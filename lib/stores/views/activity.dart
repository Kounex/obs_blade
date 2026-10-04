import 'dart:async';

import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:mobx/mobx.dart';

import '../../models/kick_auth.dart';
import '../../models/twitch_auth.dart';
import '../../models/youtube_auth.dart';
import '../../types/classes/activity/activity_event.dart';
import '../../types/enums/hive_keys.dart';
import '../../types/enums/request_type.dart';
import '../../types/enums/settings_keys.dart';
import '../../utils/activity/activity_ledger.dart';
import '../../utils/activity/activity_mappers.dart';
import '../../utils/activity/activity_persistence.dart';
import '../../utils/activity/obs_stream_destination.dart';
import '../../utils/activity/youtube_own_activity_poller.dart';
import '../../utils/general_helper.dart';
import '../../utils/get_it_helper.dart';
import '../../utils/kick/kick_events_relay_client.dart';
import '../../utils/network_helper.dart';
import '../../utils/youtube/youtube_live_chat_service.dart';
import '../pro_store.dart';
import '../shared/network.dart';
import 'dashboard.dart';
import 'kick_chat.dart';
import 'twitch_chat.dart';
import 'youtube_chat.dart';

part 'activity.g.dart';

enum ActivityFilter {
  all,
  money,
  subs,
  follows,
  raids,
  points;

  bool matches(ActivityEvent event) => switch (this) {
    ActivityFilter.all => true,
    ActivityFilter.money => event.kind.isMoney,
    ActivityFilter.subs => event.kind.isSub,
    ActivityFilter.follows => event.kind == ActivityKind.follow,
    ActivityFilter.raids =>
      event.kind == ActivityKind.raid || event.kind == ActivityKind.host,
    ActivityFilter.points =>
      event.kind == ActivityKind.redemption ||
          event.kind == ActivityKind.hypeTrain,
  };
}

/// Sums for a group header ("This stream"): money per unit (currencies,
/// bits, KICKs - never converted), and counts.
class ActivityTotals {
  final Map<String, num> amounts;
  final int follows;
  final int subs;
  final int raids;

  const ActivityTotals({
    this.amounts = const {},
    this.follows = 0,
    this.subs = 0,
    this.raids = 0,
  });

  bool get isEmpty =>
      this.amounts.isEmpty &&
      this.follows == 0 &&
      this.subs == 0 &&
      this.raids == 0;

  static ActivityTotals of(Iterable<ActivityEvent> events) {
    final amounts = <String, num>{};
    var follows = 0;
    var subs = 0;
    var raids = 0;
    for (final event in events) {
      final amount = event.amount;
      if (event.kind.isMoney && amount != null) {
        amounts[amount.unit] = (amounts[amount.unit] ?? 0) + amount.value;
      }
      switch (event.kind) {
        case ActivityKind.follow:
          follows++;
        case ActivityKind.giftSub || ActivityKind.memberGift:
          subs += (amount?.unit == ActivityUnit.subs ? amount!.value : 1)
              .toInt();
        case ActivityKind.sub ||
            ActivityKind.resub ||
            ActivityKind.member ||
            ActivityKind.memberMilestone:
          subs++;
        case ActivityKind.raid || ActivityKind.host:
          raids++;
        default:
          break;
      }
    }
    return ActivityTotals(
      amounts: amounts,
      follows: follows,
      subs: subs,
      raids: raids,
    );
  }
}

/// A run of feed rows under one header: a stream session, or a day
/// outside any session.
class ActivityGroup {
  final ActivitySession? session;

  /// Local day for non-session groups (the session's start day otherwise)
  final DateTime day;
  final List<ActivityEvent> events;

  ActivityGroup({this.session, required this.day, required this.events});

  String get key => this.session?.id ?? 'day:${this.day.toIso8601String()}';

  late final ActivityTotals totals = ActivityTotals.of(this.events);
}

/// The activity feed: what happened on the user's own channels, across
/// platforms and restarts, with seen / thanked state. Pro (it runs on
/// the native engines).
///
/// Intake: platform chat stores' `activityEvents` streams (attached like
/// `ChatTtsStore` - this store never creates YouTube's), the Kick events
/// relay, and later third-party providers - all through
/// [ActivityLedger.ingest]. Design:
/// `docs/superpowers/specs/2026-10-02-activity-feed-design.md`.
class ActivityStore = _ActivityStore with _$ActivityStore;

abstract class _ActivityStore with Store {
  static const Duration retention = Duration(days: 30);
  static const int maxEvents = 5000;

  /// A session survives a short drop (reconnect, quick restart)
  static const Duration sessionGrace = Duration(minutes: 10);

  /// Events this long before a session's start still count for it
  static const Duration sessionLead = Duration(minutes: 2);
  static const Duration _tick = Duration(seconds: 30);
  static const Duration _followerBackfillGap = Duration(minutes: 10);
  static const Duration _relayRetry = Duration(minutes: 5);

  _ActivityStore({
    ActivityPersistence? persistence,
    bool Function()? isProResolver,
    DateTime Function()? clock,
    KickEventsRelayClient? relayClient,
    bool Function()? relayEnabledResolver,
    YouTubeOwnActivityPoller? youTubePoller,
    bool attachPlatformStores = true,
  }) : _youTubePoller = youTubePoller ?? YouTubeOwnActivityPoller(),
       _persistence = persistence ?? HiveActivityPersistence(),
       _isProResolver =
           isProResolver ?? (() => GetIt.instance<ProStore>().isPro),
       _clock = clock ?? DateTime.now,
       _relayClient = relayClient ?? KickEventsRelayClient(),
       _relayEnabledResolver =
           relayEnabledResolver ??
           (() => Hive.box(
             HiveKeys.Settings.name,
           ).get(SettingsKeys.ActivityKickRelay.name, defaultValue: true)),
       _attachPlatformStores = attachPlatformStores;

  final ActivityPersistence _persistence;
  final bool Function() _isProResolver;
  final DateTime Function() _clock;
  final KickEventsRelayClient _relayClient;
  final bool Function() _relayEnabledResolver;
  final bool _attachPlatformStores;
  final YouTubeOwnActivityPoller _youTubePoller;
  AppLifecycleListener? _lifecycle;
  final List<StreamSubscription<dynamic>> _boxWatches = [];

  ActivityLedger _ledger = ActivityLedger();

  /// The own-YouTube poller's state (status banner)
  @observable
  YouTubeOwnActivityState youTubeOwnState = YouTubeOwnActivityState.off;

  /// When the own-YouTube poll resumes after a used-up quota
  @observable
  DateTime? youTubeQuotaResetAt;

  /// The connected OBS is streaming
  @observable
  bool obsLive = false;

  /// Where OBS streams to while [obsLive] (null: unknown - custom server,
  /// Kick, a multistream plugin)
  @observable
  ActivityPlatform? obsLivePlatform;

  /// Bumped on every ledger change - the computeds below read it
  @observable
  int revision = 0;

  @observable
  bool loaded = false;

  /// `platform:channel` → highest seq the user has seen
  final ObservableMap<String, int> seenMarks = ObservableMap();

  /// Marks as they were when the feed was opened - the "new since you
  /// last looked" divider holds still while the feed is on screen
  @observable
  ObservableMap<String, int>? visitMarks;

  @observable
  ActivityFilter filter = ActivityFilter.all;

  @observable
  bool toThankOnly = false;

  /// Newest first
  final ObservableList<ActivitySession> sessions = ObservableList();

  @observable
  KickRelayState relayState = KickRelayState.off;

  /// The relay has every Kick webhook subscribed (false: Kick refused some
  /// and the relay retries every 15 minutes - Pusher keeps subs and
  /// redemptions until then)
  @observable
  bool relaySubscribed = true;

  /// Live sources right now: `twitch`, `youtube`, `kick`, `kick-relay`,
  /// `obs`
  final ObservableSet<String> liveSources = ObservableSet();

  /// When the feed first ran - follower backfill never reaches further
  /// back (no flood of old follows on first use)
  DateTime? _startedAt;

  String? _relayToken;
  String? _relayUserId;
  int _relayCursor = 0;
  bool _relayRunning = false;
  DateTime? _relayRegisterFailedAt;
  Timer? _relayRetryTimer;
  Timer? _relayCursorWrite;

  /// Bumped when the relay session is dropped (sign-out, delete all data) -
  /// a registration still in flight from before must not store its session
  int _relayEpoch = 0;

  final List<ActivityEvent> _pending = [];
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final List<ReactionDisposer> _reactions = [];
  final Set<String> _attached = {};

  /// Who keeps a native coverage window open: coverer key (`twitch`,
  /// `youtube-store`, `youtube-own`, `kick`) → platform + own channel id.
  /// A platform's window is open while any of its coverers is.
  final Map<String, (ActivityPlatform, String)> _coverers = {};

  /// Channels with an open native window, per platform
  final Map<ActivityPlatform, Set<String>> _nativeOpen = {};

  /// Last moment the process was known to run (tick / coverage change) -
  /// a longer silence was a freeze (iOS suspended the app)
  DateTime? _aliveAt;
  static const Duration _freezeGap = Duration(seconds: 75);

  /// Bumped when coverage changes (gaps read it)
  @observable
  int coverageRevision = 0;

  /// Bumped every 30 s tick - a running gap crosses the 1-minute floor
  /// without any other change
  @observable
  int clockTick = 0;

  /// Bumped when a sign-in / setup value in Hive changes (YouTube session,
  /// API key, OAuth client, the Kick relay switch) - the status banner
  /// reads those off Hive
  @observable
  int setupRevision = 0;

  /// Status banner lines the user has seen (expanded or tucked away) -
  /// the tucked button badges the others
  final ObservableSet<String> acknowledgedStatus = ObservableSet();

  /// A YouTube chat's first page re-sends recent history: attaching
  /// covers about this much before it
  static const Duration _youTubeHistoryReach = Duration(minutes: 2);
  DateTime? _lastFollowerBackfill;
  Timer? _ticker;
  int _ticks = 0;
  bool _initialized = false;

  // Derived state

  List<ActivityEvent> _sorted() {
    final list = this._ledger.events.toList()
      ..sort((a, b) {
        final byTime = b.timestamp.compareTo(a.timestamp);
        return byTime != 0 ? byTime : b.seq.compareTo(a.seq);
      });
    return list;
  }

  /// Every row, newest first
  @computed
  List<ActivityEvent> get allEvents {
    this.revision;
    return this._sorted();
  }

  String _channelKey(ActivityEvent event) =>
      '${event.platform.name}:${event.channelId}';

  bool _unseenIn(Map<String, int> marks, ActivityEvent event) =>
      event.seq > (marks[this._channelKey(event)] ?? 0);

  /// Rows the user hasn't seen (badge, "N new" chip)
  @computed
  int get unseenCount {
    this.revision;
    var count = 0;
    for (final event in this._ledger.events) {
      if (this._unseenIn(this.seenMarks, event)) count++;
    }
    return count;
  }

  /// Big rows not thanked yet
  @computed
  int get toThankCount {
    this.revision;
    return this._ledger.events.where((e) => e.isBig && !e.thanked).length;
  }

  /// "New since you last looked" for the feed on screen
  bool isNew(ActivityEvent event) =>
      this._unseenIn(this.visitMarks ?? this.seenMarks, event);

  @computed
  List<ActivityEvent> get visibleEvents => [
    for (final event in this.allEvents)
      if (this.filter.matches(event) &&
          (!this.toThankOnly || (event.isBig && !event.thanked)))
        event,
  ];

  /// [visibleEvents] under session / day headers, newest first
  @computed
  List<ActivityGroup> get groups {
    final now = this._clock().toUtc();
    final groups = <ActivityGroup>[];
    for (final event in this.visibleEvents) {
      final session = this.sessionOf(event.timestamp, now: now);
      final local = event.timestamp.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      final last = groups.isEmpty ? null : groups.last;
      if (last != null &&
          (session != null
              ? last.session?.id == session.id
              : last.session == null && last.day == day)) {
        last.events.add(event);
        continue;
      }
      final sessionLocal = session?.start.toLocal();
      groups.add(
        ActivityGroup(
          session: session,
          day: sessionLocal == null
              ? day
              : DateTime(
                  sessionLocal.year,
                  sessionLocal.month,
                  sessionLocal.day,
                ),
          events: [event],
        ),
      );
    }
    return groups;
  }

  /// The session [at] falls in, if any
  ActivitySession? sessionOf(DateTime at, {DateTime? now}) {
    final moment = at.toUtc();
    final current = (now ?? this._clock()).toUtc();
    for (final session in this.sessions) {
      final start = session.start.subtract(sessionLead);
      final end = (session.end ?? current).add(sessionGrace);
      if (!moment.isBefore(start) && !moment.isAfter(end)) return session;
    }
    return null;
  }

  /// The open session, if live now
  ActivitySession? get currentSession =>
      this.sessions.isNotEmpty && this.sessions.first.isOpen
      ? this.sessions.first
      : null;

  /// Every row of one person on one platform, newest first (person sheet)
  List<ActivityEvent> historyOf(ActivityEvent event) => [
    for (final other in this.allEvents)
      if (other.platform == event.platform &&
          !other.actor.anonymous &&
          other.actor.sameAs(event.actor))
        other,
  ];

  // Lifecycle

  /// Open the boxes, restore, start attaching. Safe to call twice.
  Future<void> init() async {
    if (this._initialized) return;
    this._initialized = true;
    try {
      await this._persistence.open();
      this._load();
    } catch (e) {
      GeneralHelper.logFailure('Activity feed: could not open storage', e);
    }
    runInAction(() => this.loaded = true);
    for (final event in List.of(this._pending)) {
      this._ingest(event);
    }
    this._pending.clear();
    this._prune();
    this._ticker = Timer.periodic(_tick, (_) => this._onTick());
    this._youTubePoller
      ..onEvent = this.ingest
      ..onChanged = this._onYouTubeOwnChanged;
    if (this._attachPlatformStores) {
      this._reactions.add(
        reaction<bool>((_) => this._isProResolver(), (pro) {
          if (pro) this._createSignedInStores();
          this._syncRelay();
          this._syncYouTubeOwn();
        }, fireImmediately: true),
      );
      this._watchYouTubeSetup();
      this._listenToLifecycle();
      this.chatStoreCreated();
    }
  }

  /// Foreground / background: the own-YouTube poller only checks for a
  /// stream while someone may look; a resume catches up a freeze at once.
  void _listenToLifecycle() {
    try {
      this._lifecycle = AppLifecycleListener(
        onResume: () {
          this._catchUpFreeze(this._clock());
          this._youTubePoller.foreground = true;
        },
        onHide: () => this._youTubePoller.foreground = false,
      );
    } catch (e) {
      /// No widgets binding (headless tests) - stays "foreground"
      GeneralHelper.advLog('Activity feed: no lifecycle - $e');
    }
  }

  // Own YouTube channel (no YouTube store needed)

  /// The sign-in (own channel id) or the API key changed: the poller
  /// follows. Read off Hive - never creates the YouTube store.
  void _watchYouTubeSetup() {
    void changed() {
      this._syncYouTubeOwn();
      runInAction(() => this.setupRevision++);
    }

    const settingKeys = {
      SettingsKeys.YouTubeApiKey,
      SettingsKeys.YouTubeOAuthClientId,
      SettingsKeys.YouTubeSignedInWithoutChannel,
      SettingsKeys.ActivityKickRelay,
    };
    try {
      if (Hive.isBoxOpen(HiveKeys.YouTubeAuth.name)) {
        this._boxWatches.add(
          Hive.box<YouTubeAuth>(
            HiveKeys.YouTubeAuth.name,
          ).watch().listen((_) => changed()),
        );
      }
      if (Hive.isBoxOpen(HiveKeys.Settings.name)) {
        this._boxWatches.add(
          Hive.box(HiveKeys.Settings.name).watch().listen((event) {
            if (settingKeys.any((key) => key.name == event.key)) changed();
          }),
        );
      }
    } catch (e) {
      GeneralHelper.logFailure('Activity feed: YouTube setup watch failed', e);
    }
  }

  /// Signed in to YouTube with a channel (the stored session)
  String? get _youTubeChannelId {
    try {
      if (!Hive.isBoxOpen(HiveKeys.YouTubeAuth.name)) return null;
      return Hive.box<YouTubeAuth>(
        HiveKeys.YouTubeAuth.name,
      ).get(YouTubeAuth.kBoxKey)?.channelId;
    } catch (_) {
      return null;
    }
  }

  void _syncYouTubeOwn() {
    if (!this._attachPlatformStores) return;
    this._youTubePoller.configure(
      channelId: this._youTubeChannelId,
      apiKey: YouTubeLiveChatService.resolveApiKey(),
      enabled: this._isProResolver(),
    );
  }

  void _onYouTubeOwnChanged() {
    final poller = this._youTubePoller;
    final live = poller.state == YouTubeOwnActivityState.live;
    runInAction(() {
      this.youTubeOwnState = poller.state;
      this.youTubeQuotaResetAt = poller.quotaResetAt;
    });
    this._setCoverer(
      'youtube-own',
      ActivityPlatform.youtube,
      live ? poller.channelId : null,
    );
    this._setLive('youtube-own', live, since: live ? poller.liveSince : null);
  }

  void _load() {
    final state = this._persistence.loadMeta('state');
    var seq = 0;
    if (state is Map) {
      this._startedAt = DateTime.tryParse('${state['startedAt']}')?.toUtc();
      seq = (state['seq'] as num?)?.toInt() ?? 0;
      final relay = state['relay'];
      if (relay is Map) {
        this._relayToken = relay['token'] as String?;
        this._relayUserId = relay['userId'] as String?;
        this._relayCursor = (relay['cursor'] as num?)?.toInt() ?? 0;
      }
    }
    final now = this._clock().toUtc();
    this._startedAt ??= now;
    final heartbeat = DateTime.tryParse(
      '${this._persistence.loadMeta('heartbeat')}',
    )?.toUtc();
    final coverage = ActivityCoverage.fromJson(
      this._persistence.loadMeta('coverage'),
    );

    /// Nothing is connected yet - a window left open by a kill ends when
    /// the app was last alive, it must not claim the downtime
    coverage.closeAfterKill(heartbeat);
    this._ledger = ActivityLedger(coverage: coverage, seq: seq);
    for (final event in this._persistence.loadEvents()) {
      this._ledger.restore(event);
    }

    final seen = this._persistence.loadMeta('seen');
    final statusSeen = this._persistence.loadMeta('statusSeen');
    final rawSessions = this._persistence.loadMeta('sessions');
    runInAction(() {
      if (statusSeen is List) {
        this.acknowledgedStatus.addAll(statusSeen.whereType<String>());
      }
      if (seen is Map) {
        this.seenMarks.addAll({
          for (final entry in seen.entries)
            if (entry.key is String && entry.value is num)
              entry.key as String: (entry.value as num).toInt(),
        });
      }
      if (rawSessions is List) {
        for (final raw in rawSessions) {
          final session = ActivitySession.fromJson(raw);
          if (session == null) continue;

          /// Left open by a kill: it ended at the last heartbeat - if
          /// that was written for this session, not the one before
          this.sessions.add(
            session.isOpen
                ? session.copyWith(
                    end: heartbeat != null && heartbeat.isAfter(session.start)
                        ? heartbeat
                        : session.start,
                  )
                : session,
          );
        }
        this.sessions.sort((a, b) => b.start.compareTo(a.start));
      }

      /// A feed that opened before the marks were read froze an empty
      /// snapshot - everything would read as new
      if (this.visitMarks != null) {
        this.visitMarks = ObservableMap.of(this.seenMarks);
      }
      this.revision++;
    });
    this._saveState();
  }

  /// A platform chat store was just created (`main.dart` hooks every
  /// chat store's `onCreated` here) - listen to it.
  void chatStoreCreated() {
    if (!this._attachPlatformStores || !this.loaded) return;
    final getIt = GetIt.instance;
    if (!this._attached.contains('twitch') &&
        lazySingletonCreated<TwitchChatStore>()) {
      this._attached.add('twitch');
      this._attachTwitch(getIt<TwitchChatStore>());
    }
    if (!this._attached.contains('youtube') &&
        lazySingletonCreated<YouTubeChatStore>()) {
      this._attached.add('youtube');
      this._attachYouTube(getIt<YouTubeChatStore>());
    }
    if (!this._attached.contains('kick') &&
        lazySingletonCreated<KickChatStore>()) {
      this._attached.add('kick');
      this._attachKick(getIt<KickChatStore>());
    }
  }

  /// Pro + signed in: bring up the Twitch / Kick stores so the feed
  /// collects without the chat being opened. YouTube stays lazy - its
  /// poll spends API quota.
  void _createSignedInStores() {
    final getIt = GetIt.instance;
    try {
      if (getIt.isRegistered<TwitchChatStore>() &&
          Hive.isBoxOpen(HiveKeys.TwitchAuth.name) &&
          Hive.box<TwitchAuth>(
                HiveKeys.TwitchAuth.name,
              ).get(TwitchAuth.kBoxKey) !=
              null) {
        getIt<TwitchChatStore>();
      }
      if (getIt.isRegistered<KickChatStore>() &&
          Hive.isBoxOpen(HiveKeys.KickAuth.name) &&
          Hive.box<KickAuth>(HiveKeys.KickAuth.name).get(KickAuth.kBoxKey) !=
              null) {
        getIt<KickChatStore>();
      }
    } catch (e) {
      GeneralHelper.logFailure('Activity feed: store start failed', e);
    }
    this.chatStoreCreated();
  }

  void _attachTwitch(TwitchChatStore twitch) {
    this._subscriptions.add(twitch.activityEvents.listen(this.ingest));
    this._reactions
      ..add(
        reaction<String?>(
          (_) => twitch.chatConnection == TwitchChatConnectionState.live
              ? twitch.user?.id
              : null,
          (ownId) {
            this._setCoverer('twitch', ActivityPlatform.twitch, ownId);
            if (ownId != null) unawaited(this._backfillTwitchFollowers(twitch));
          },
          fireImmediately: true,
        ),
      )
      ..add(
        reaction<(bool, DateTime?)>(
          (_) => (
            twitch.user != null && twitch.isChannelLive(null),
            twitch.channelLiveSince[twitch.user?.id],
          ),
          (state) => this._setLive('twitch', state.$1, since: state.$2),
          fireImmediately: true,
        ),
      );
  }

  void _attachYouTube(YouTubeChatStore youTube) {
    this._subscriptions.add(youTube.activityEvents.listen(this.ingest));

    /// The chat reads the own chat itself: the poller stands by (no
    /// second poll on the same quota)
    this._reactions.add(
      reaction<bool>(
        (_) =>
            youTube.isViewingOwnChannel &&
            youTube.chatConnection == YouTubeChatConnectionState.connected,
        (covered) => this._youTubePoller.standby = covered,
        fireImmediately: true,
      ),
    );
    this._reactions.add(
      reaction<String?>(
        (_) =>
            youTube.isViewingOwnChannel &&
                youTube.chatConnection == YouTubeChatConnectionState.connected
            ? youTube.selfChannelId
            : null,
        (ownId) {
          this._setCoverer('youtube-store', ActivityPlatform.youtube, ownId);

          /// YouTube only connects to a live broadcast's chat
          this._setLive('youtube', ownId != null);
        },
        fireImmediately: true,
      ),
    );
  }

  void _attachKick(KickChatStore kick) {
    this._subscriptions.add(kick.activityEvents.listen(this.ingest));
    this._reactions
      ..add(
        reaction<String?>(
          (_) =>
              kick.ownChannelSlug != null &&
                  kick.isOwnChannel(kick.selectedChannelSlug) &&
                  kick.chatConnection == KickChatConnectionState.connected
              ? kick.selfUserId?.toString()
              : null,
          (ownId) => this._setCoverer('kick', ActivityPlatform.kick, ownId),
          fireImmediately: true,
        ),
      )
      ..add(
        reaction<bool>(
          (_) =>
              kick.isOwnChannel(kick.selectedChannelSlug) &&
              (kick.channelInfo?.isLive ?? false),
          (live) => this._setLive('kick', live),
          fireImmediately: true,
        ),
      )
      ..add(
        reaction<String?>(
          (_) => kick.ownChannelSlug,
          (_) => this._syncRelay(),
          fireImmediately: true,
        ),
      );
  }

  // Intake

  /// Every source ends here. Before [init] finished, events wait.
  @action
  void ingest(ActivityEvent event) {
    if (!this.loaded) {
      this._pending.add(event);
      return;
    }
    this._ingest(event);
  }

  void _ingest(ActivityEvent event) {
    final result = this._ledger.ingest(event);
    final stored = result.event;
    if (stored == null) return;
    unawaited(this._persistence.putEvent(stored));
    if (result.outcome == ActivityIngestOutcome.inserted) this._saveState();
    runInAction(() => this.revision++);
  }

  /// [key] covers [platform]'s own [channelId] now (null: not anymore).
  void _setCoverer(String key, ActivityPlatform platform, String? channelId) {
    final previous = this._coverers[key];
    if (channelId == null
        ? previous == null
        : previous == (platform, channelId)) {
      return;
    }
    if (channelId == null) {
      this._coverers.remove(key);
    } else {
      this._coverers[key] = (platform, channelId);
    }
    this._applyNativeCoverage(platform);
    if (previous != null && previous.$1 != platform) {
      this._applyNativeCoverage(previous.$1);
    }
  }

  void _applyNativeCoverage(ActivityPlatform platform) {
    final now = this._clock();
    this._catchUpFreeze(now);
    final wanted = {
      for (final (p, channel) in this._coverers.values)
        if (p == platform) channel,
    };
    final open = this._nativeOpen.putIfAbsent(platform, () => {});
    final openAt = platform == ActivityPlatform.youtube
        ? now.subtract(_youTubeHistoryReach)
        : now;
    var changed = false;
    for (final channel in open.difference(wanted)) {
      changed |= this._ledger.coverage.close(
        ActivitySource.native,
        platform,
        channel,
        now,
      );
    }
    for (final channel in wanted.difference(open)) {
      changed |= this._ledger.coverage.open(
        ActivitySource.native,
        platform,
        channel,
        openAt,
      );
    }
    open
      ..clear()
      ..addAll(wanted);
    if (changed) this._saveCoverage();
  }

  /// A silence longer than [_freezeGap] since the process was last alive
  /// means it was frozen (iOS suspends a backgrounded app; timers stop,
  /// sockets die): what was "open" didn't listen then.
  void _catchUpFreeze(DateTime now) {
    final alive = this._aliveAt;
    this._aliveAt = now;
    if (alive == null || now.difference(alive) <= _freezeGap) return;
    if (this._ledger.coverage.splitOpen(
      alive,
      now,
      except: const {ActivityPlatform.youtube},
    )) {
      this._saveCoverage();
    }
  }

  Future<void> _backfillTwitchFollowers(TwitchChatStore twitch) async {
    final now = this._clock();
    final last = this._lastFollowerBackfill;
    if (last != null && now.difference(last) < _followerBackfillGap) return;
    this._lastFollowerBackfill = now;
    final rows = await twitch.recentFollowerActivity();
    final floor = [
      this._startedAt ?? now,
      now.subtract(retention),
    ].reduce((a, b) => a.isAfter(b) ? a : b);
    runInAction(() {
      for (final row in rows.reversed) {
        if (row.timestamp.isAfter(floor)) this._ingest(row);
      }
    });
  }

  // Sessions

  /// [since]: when the platform says the stream started (Twitch Helix
  /// `started_at`, Kick relay `started_at`) - a session opened mid-stream
  /// (app started late) reaches back to it.
  void _setLive(
    String source,
    bool live, {
    DateTime? since,
    DateTime? endedAt,
  }) => runInAction(() {
    var changed = live
        ? this.liveSources.add(source)
        : this.liveSources.remove(source);
    if (live && since != null && this._liveSince[source] != since) {
      this._liveSince[source] = since.toUtc();
      changed = true;
    }
    if (!live) this._liveSince.remove(source);
    if (changed) this._syncSession(endedAt: endedAt);
  });

  /// Platform-reported stream start per live source
  final Map<String, DateTime> _liveSince = {};

  /// [endedAt]: when the platform says the stream ended (relay backlog
  /// replaying an old offline) - the session ends there, not now.
  @action
  void _syncSession({DateTime? endedAt}) {
    final now = this._clock().toUtc();
    final platforms = <ActivityPlatform>{
      for (final source in this.liveSources)
        ?switch (source) {
          'twitch' => ActivityPlatform.twitch,
          'youtube' || 'youtube-own' => ActivityPlatform.youtube,
          'kick' || 'kick-relay' => ActivityPlatform.kick,
          _ => null,
        },
    };
    final last = this.sessions.isEmpty ? null : this.sessions.first;
    final previousEnd = this.sessions.length > 1 ? this.sessions[1].end : null;

    /// Earliest platform-reported start, never in the future
    DateTime? since;
    for (final value in this._liveSince.values) {
      if (since == null || value.isBefore(since)) since = value;
    }
    if (since != null && since.isAfter(now)) since = now;
    if (this.liveSources.isNotEmpty) {
      /// Same broadcast when it (re)started within the grace of the last
      /// end - or before it (the app was closed while the stream ran on)
      final startedAt = since ?? now;
      if (last != null &&
          (last.isOpen || startedAt.difference(last.end!) <= sessionGrace)) {
        /// Reaching back never crosses into the session before
        final reachBack =
            since != null &&
            since.isBefore(last.start) &&
            (previousEnd == null || since.isAfter(previousEnd));
        this.sessions[0] = last.copyWith(
          clearEnd: true,
          platforms: {...last.platforms, ...platforms},
          start: reachBack ? since : null,
        );
      } else {
        /// Reaching back is only for the stream that is live now - a start
        /// before the previous session's end would swallow it
        final previousEnd = last?.end;
        final start =
            since != null && (previousEnd == null || since.isAfter(previousEnd))
            ? since
            : now;
        this.sessions.insert(
          0,
          ActivitySession(
            id: 's${now.millisecondsSinceEpoch}',
            start: start,
            platforms: platforms,
          ),
        );
      }
    } else if (last != null && last.isOpen) {
      final reported = endedAt?.toUtc();
      this.sessions[0] = last.copyWith(
        end:
            reported != null &&
                reported.isBefore(now) &&
                reported.isAfter(last.start)
            ? reported
            : now,
      );
    } else {
      return;
    }
    this._saveSessions();
    if (this.currentSession != null) this._writeHeartbeat();
    this.revision++;
  }

  /// While live: a kill closes the session here on the next start
  void _writeHeartbeat() => unawaited(
    this._persistence.putMeta(
      'heartbeat',
      this._clock().toUtc().toIso8601String(),
    ),
  );

  void _onTick() {
    this._ticks++;
    this._catchUpFreeze(this._clock());
    runInAction(() => this.clockTick++);

    /// Every 6 h while running
    if (this._ticks % 720 == 0) this._prune();

    /// Not Pro: nothing is collected, so no stream sessions either (no
    /// OBS reads, no heartbeats)
    if (!this._isProResolver()) {
      this._setLive('obs', false);
      this._syncObs(false);
      this._syncYouTubeOwn();
      return;
    }

    /// OBS streaming counts as live too (no platform needed)
    final obsLive =
        lazySingletonCreated<DashboardStore>() &&
        GetIt.instance<DashboardStore>().isLive;
    this._setLive('obs', obsLive);
    this._syncObs(obsLive);
    this._syncYouTubeOwn();

    /// The last alive moment: a kill ends sessions and coverage there
    if (this.currentSession != null || this._ledger.coverage.anyOpen) {
      this._writeHeartbeat();
    }
  }

  /// OBS went live (or is live when first seen): ask once where it
  /// streams to; a stream to YouTube - or anywhere unknown, multistream
  /// plugins hide YouTube - checks for the own YouTube stream every 30 s.
  void _syncObs(bool live) {
    if (live == this.obsLive) return;
    runInAction(() {
      this.obsLive = live;
      if (!live) this.obsLivePlatform = null;
    });
    this._youTubePoller.fast = live;
    if (live) unawaited(this._readObsDestination());
  }

  Future<void> _readObsDestination() async {
    try {
      if (!lazySingletonCreated<NetworkStore>()) return;
      final session = GetIt.instance<NetworkStore>().activeSession;
      if (session == null) return;
      final ack = await NetworkHelper.makeScopedRequest(
        session.socket,
        RequestType.GetStreamServiceSettings,
      );
      if (!ack.success || !this.obsLive) return;
      final platform = obsStreamPlatform(ack.responseData);
      runInAction(() => this.obsLivePlatform = platform);

      /// Known to stream elsewhere (Twitch): no need to look for the own
      /// YouTube stream every 30 s
      this._youTubePoller.fast =
          platform == null || platform == ActivityPlatform.youtube;
    } catch (e) {
      GeneralHelper.logFailure(
        'Activity feed: OBS stream service read failed',
        e,
      );
    }
  }

  /// OBS streaming state from a test (no dashboard / socket).
  void setObsLiveForTest(bool live, {ActivityPlatform? platform}) {
    this._syncObs(live);
    runInAction(() => this.obsLivePlatform = live ? platform : null);
  }

  // Seen / thanked

  @action
  void markAllSeen() {
    final top = <String, int>{};
    for (final event in this._ledger.events) {
      final key = this._channelKey(event);
      if (event.seq > (top[key] ?? 0)) top[key] = event.seq;
    }
    var changed = false;
    for (final entry in top.entries) {
      if ((this.seenMarks[entry.key] ?? 0) < entry.value) {
        this.seenMarks[entry.key] = entry.value;
        changed = true;
      }
    }
    if (changed) {
      unawaited(this._persistence.putMeta('seen', Map.of(this.seenMarks)));
    }
  }

  /// Feeds on screen right now (tablet pane + a sheet can overlap)
  int _visits = 0;

  /// A feed came on screen: freeze the divider at what was seen before.
  @action
  void beginVisit() {
    this._visits++;
    this.visitMarks ??= ObservableMap.of(this.seenMarks);
  }

  /// A feed left the screen; when the last one goes, what they showed is
  /// seen.
  @action
  void endVisit() {
    if (this._visits == 0) return;
    this._visits--;
    if (this._visits > 0) return;
    this.visitMarks = null;
    this._markShownSeen();
  }

  /// Whether [event] is on screen in the current view (filter chip +
  /// "To thank")
  bool _shown(ActivityEvent event) =>
      this.filter.matches(event) &&
      (!this.toThankOnly || (event.isBig && !event.thanked));

  /// Leaving the feed: what it could show is seen - rows the filter or
  /// "To thank" hid stay new (the badge / "N new" chip promised them). The
  /// mark is a per-channel high-water seq, so it stops below the oldest
  /// hidden unseen row of that channel.
  void _markShownSeen() {
    final top = <String, int>{};
    final cap = <String, int>{};
    for (final event in this._ledger.events) {
      if (!this._unseenIn(this.seenMarks, event)) continue;
      final key = this._channelKey(event);
      if (this._shown(event)) {
        if (event.seq > (top[key] ?? 0)) top[key] = event.seq;
      } else if (event.seq < (cap[key] ?? 1 << 62)) {
        cap[key] = event.seq;
      }
    }
    var changed = false;
    for (final entry in top.entries) {
      final limit = cap[entry.key];
      final mark = limit == null || limit > entry.value
          ? entry.value
          : limit - 1;
      if ((this.seenMarks[entry.key] ?? 0) < mark) {
        this.seenMarks[entry.key] = mark;
        changed = true;
      }
    }
    if (changed) {
      unawaited(this._persistence.putMeta('seen', Map.of(this.seenMarks)));
    }
  }

  @action
  void setThanked(ActivityEvent event, bool thanked) {
    final stored = this._ledger[event.id];
    if (stored == null || stored.thanked == thanked) return;
    final updated = stored.copyWith(thanked: thanked);
    this._ledger.update(updated);
    unawaited(this._persistence.putEvent(updated));
    this.revision++;
  }

  /// The status banner showed [ids] (expanded, or the user tucked it):
  /// they stop badging. Lines that went away drop out, so one coming back
  /// later badges again.
  @action
  void acknowledgeStatus(Iterable<String> ids) {
    final next = ids.toSet();
    if (next.length == this.acknowledgedStatus.length &&
        next.containsAll(this.acknowledgedStatus)) {
      return;
    }
    this.acknowledgedStatus
      ..clear()
      ..addAll(next);
    unawaited(this._persistence.putMeta('statusSeen', next.toList()));
  }

  /// The store's clock (tests drive it)
  DateTime get now => this._clock();

  /// The Kick relay switch (options sheet / status banner)
  bool get relayEnabled => this._relayEnabled();

  /// Mark [events] thanked in one go (a stream's / day's header).
  @action
  void markThanked(Iterable<ActivityEvent> events) {
    var changed = false;
    for (final event in events) {
      final stored = this._ledger[event.id];
      if (stored == null || !stored.isBig || stored.thanked) continue;
      final updated = stored.copyWith(thanked: true);
      this._ledger.update(updated);
      unawaited(this._persistence.putEvent(updated));
      changed = true;
    }
    if (changed) this.revision++;
  }

  // Gaps

  /// Where [session] wasn't listened to, per platform of the session,
  /// oldest first. Kick with the relay never has gaps: the relay keeps
  /// what arrives while the app is closed and replays it.
  List<ActivityGap> gapsOf(ActivitySession session, {DateTime? now}) {
    this.coverageRevision;
    final current = (now ?? this._clock()).toUtc();
    final end = session.end ?? current;
    final gaps = <ActivityGap>[];
    for (final platform in ActivityPlatform.values) {
      if (!session.platforms.contains(platform)) continue;
      if (platform == ActivityPlatform.kick && this._relayToken != null) {
        continue;
      }

      /// Older coverage was dropped (window cap): unknown, not a gap
      final truncated = this._ledger.coverage.truncatedBefore(platform);
      if (truncated != null && session.start.isBefore(truncated)) continue;
      gaps.addAll(
        coverageGaps(
          platform,
          this._ledger.coverage.windowsFor(platform),
          session.start,
          end,
          open: session.isOpen,
        ),
      );
    }
    gaps.sort((a, b) => a.start.compareTo(b.start));
    return gaps;
  }

  @action
  void setFilter(ActivityFilter filter) => this.filter = filter;

  @action
  void setToThankOnly(bool value) => this.toThankOnly = value;

  /// Forget every row (sessions and coverage stay). The follower
  /// backfill starts from here too - cleared follows don't come back.
  @action
  Future<void> clearHistory() async {
    final ids = this._ledger.events.map((e) => e.id).toList();
    for (final id in ids) {
      this._ledger.remove(id);
    }
    this.seenMarks.clear();
    this.visitMarks = null;
    this._startedAt = this._clock().toUtc();
    this._saveState();
    this.revision++;
    await this._persistence.clearEvents();
    await this._persistence.putMeta('seen', null);
  }

  // Kick events relay

  bool get relayWanted {
    final kick = this._attached.contains('kick')
        ? GetIt.instance<KickChatStore>()
        : null;
    return kick != null &&
        kick.ownChannelSlug != null &&
        kick.selfUserId != null &&
        this._isProResolver() &&
        this._relayEnabled();
  }

  bool _relayEnabled() {
    try {
      return this._relayEnabledResolver();
    } catch (_) {
      return true;
    }
  }

  /// Start / stop the relay to match Pro, the Kick sign-in and the
  /// setting. Called on every change of those.
  void _syncRelay() {
    if (!this._attachPlatformStores) return;
    final kick = this._attached.contains('kick')
        ? GetIt.instance<KickChatStore>()
        : null;
    final selfId = this._kickSelfId(kick);

    /// Signed out of Kick, another account, or the setting turned off:
    /// the relay forgets that channel's data
    ///
    /// Signed out = no stored Kick session. Not `ownChannelSlug`: that is
    /// null until the store's async auth restore finished, and reading
    /// it then deleted the backlog the relay kept, on every launch.
    if (this._relayToken != null &&
        (selfId == null ||
            selfId != this._relayUserId ||
            !this._relayEnabled())) {
      final token = this._relayToken!;
      this._relayEpoch++;
      this._relayCoverage(false);
      if (this._relayRunning) {
        this._relayRunning = false;
        unawaited(this._relayClient.stop());
      }
      unawaited(this._relayClient.unregister(token));
      this._forgetRelaySession();
      this._setLive('kick-relay', false);
    }
    if (!this.relayWanted) {
      if (this._relayRunning) {
        /// A sign-in still in flight drops its session when it lands
        this._relayEpoch++;
        this._relayRunning = false;
        unawaited(this._relayClient.stop());
      }
      this._relayCoverage(false);
      runInAction(() => this.relayState = KickRelayState.off);
      this._setLive('kick-relay', false);
      return;
    }
    if (!this._relayRunning) unawaited(this._startRelay(kick!));
  }

  /// The signed-in Kick user id from the stored session - read from the
  /// box so a sign-out is seen even when the Kick store doesn't exist
  String? _kickSelfId(KickChatStore? kick) {
    try {
      if (Hive.isBoxOpen(HiveKeys.KickAuth.name)) {
        return Hive.box<KickAuth>(
          HiveKeys.KickAuth.name,
        ).get(KickAuth.kBoxKey)?.userId?.toString();
      }
    } catch (_) {}
    return kick?.selfUserId?.toString();
  }

  /// The setting changed (options sheet).
  void relaySettingChanged() => this._syncRelay();

  Future<void> _startRelay(KickChatStore kick) async {
    this._relayRunning = true;
    final epoch = this._relayEpoch;
    final selfId = '${kick.selfUserId}';
    var token = this._relayUserId == selfId ? this._relayToken : null;
    if (token == null) {
      final failedAt = this._relayRegisterFailedAt;
      if (failedAt != null &&
          this._clock().difference(failedAt) < _relayRetry) {
        this._scheduleRelayRetry();
        this._relayRunning = false;
        return;
      }
      runInAction(() => this.relayState = KickRelayState.registering);
      try {
        final session = await this._relayClient.register(
          await kick.relayAccessToken(),
        );

        /// Signed out or deleted meanwhile: that session isn't wanted
        if (epoch != this._relayEpoch) {
          unawaited(this._relayClient.unregister(session.token));
          return;
        }
        token = session.token;
        this._relayToken = session.token;
        this._relayUserId = session.broadcasterUserId;
        this._relayCursor = 0;
        this._relayRegisterFailedAt = null;
        this._saveState();
      } catch (e) {
        if (epoch != this._relayEpoch) return;
        GeneralHelper.logFailure('Kick relay sign-in failed', e);
        this._relayRegisterFailedAt = this._clock();
        this._relayRunning = false;
        runInAction(() => this.relayState = KickRelayState.retrying);
        this._scheduleRelayRetry();
        return;
      }
    }
    if (!this.relayWanted) {
      this._relayRunning = false;
      runInAction(() => this.relayState = KickRelayState.off);
      return;
    }
    this._relayClient.start(
      sessionToken: token,
      cursor: () => this._relayCursor,
      onEvent: this.handleRelayFrame,
      onState: (state) {
        runInAction(() => this.relayState = state);
        this._relayCoverage(state == KickRelayState.synced);
      },
      onSubscribed: (subscribed) {
        runInAction(() => this.relaySubscribed = subscribed);
        this._relayCoverage(this.relayState == KickRelayState.synced);
      },
      onUnknownSession: () {
        this._forgetRelaySession();
        this._relayRunning = false;
        this._scheduleRelayRetry(soon: true);
      },
    );
  }

  void _scheduleRelayRetry({bool soon = false}) {
    this._relayRetryTimer?.cancel();
    this._relayRetryTimer = Timer(
      soon ? const Duration(seconds: 5) : _relayRetry,
      this._syncRelay,
    );
  }

  void _forgetRelaySession() {
    this._relayToken = null;
    this._relayUserId = null;
    this._relayCursor = 0;
    this._saveState();
  }

  /// The relay owns Kick's sub / gift / redemption rows only while it is
  /// synced and Kick delivers all of them - otherwise Pusher's copies stay.
  void _relayCoverage(bool synced) {
    final channel = this._relayUserId;
    if (channel == null) return;
    final now = this._clock();
    this._catchUpFreeze(now);
    final changed = synced && this.relaySubscribed
        ? this._ledger.coverage.open(
            ActivitySource.kickRelay,
            ActivityPlatform.kick,
            channel,
            now,
          )
        : this._ledger.coverage.close(
            ActivitySource.kickRelay,
            ActivityPlatform.kick,
            channel,
            now,
          );
    if (changed) this._saveCoverage();
  }

  /// One relay `event` frame (public for tests).
  void handleRelayFrame(Map<String, Object?> frame) {
    final seq = (frame['seq'] as num?)?.toInt();
    if (seq != null && seq > this._relayCursor) {
      this._relayCursor = seq;
      this._relayCursorWrite?.cancel();
      this._relayCursorWrite = Timer(
        const Duration(seconds: 2),
        this._saveState,
      );
    }
    final status = kickRelayLiveStatus(frame);
    if (status != null) {
      this._applyRelayStatus(status);
      return;
    }
    final event = kickActivityFromRelay(frame);
    if (event != null) runInAction(() => this.ingest(event));
  }

  void _applyRelayStatus((String, bool, DateTime) status) {
    final (channel, live, at) = status;
    if (channel != this._relayUserId || this._olderThanSessions(live, at)) {
      return;
    }
    this._setLive(
      'kick-relay',
      live,
      since: live ? at : null,
      endedAt: live ? null : at,
    );
  }

  /// A replayed status from before the newest session (the backlog sent
  /// again after a new relay sign-in) - it would drag that session back
  /// days. Streams after it still open their own sessions.
  bool _olderThanSessions(bool live, DateTime at) {
    if (this.sessions.isEmpty) return false;
    final newest = this.sessions.first;
    final moment = at.toUtc();
    if (!live) return moment.isBefore(newest.start);
    if (!moment.isBefore(newest.start.subtract(sessionGrace))) return false;

    /// Live now and opened late: reaching back is fine up to the session
    /// before
    final previousEnd = this.sessions.length > 1 ? this.sessions[1].end : null;
    return !(newest.isOpen &&
        (previousEnd == null || moment.isAfter(previousEnd)));
  }

  // Persistence

  void _saveState() {
    unawaited(
      this._persistence.putMeta('state', {
        'startedAt': this._startedAt?.toIso8601String(),
        'seq': this._ledger.seq,
        if (this._relayToken != null)
          'relay': {
            'token': this._relayToken,
            'userId': this._relayUserId,
            'cursor': this._relayCursor,
          },
      }),
    );
  }

  void _saveCoverage() {
    runInAction(() => this.coverageRevision++);
    unawaited(
      this._persistence.putMeta('coverage', this._ledger.coverage.toJson()),
    );
  }

  void _saveSessions() => unawaited(
    this._persistence.putMeta('sessions', [
      for (final session in this.sessions) session.toJson(),
    ]),
  );

  /// 30 days, 5,000 rows, old sessions and coverage.
  void _prune() {
    final now = this._clock().toUtc();
    final cutoff = now.subtract(retention);
    final events = this._sorted();
    final drop = <String>[
      for (var i = 0; i < events.length; i++)
        if (i >= maxEvents || events[i].timestamp.isBefore(cutoff))
          events[i].id,
    ];
    for (final id in drop) {
      this._ledger.remove(id);
    }
    if (drop.isNotEmpty) unawaited(this._persistence.deleteEvents(drop));
    this._ledger.coverage.prune(cutoff);
    final before = this.sessions.length;
    runInAction(() {
      this.sessions.removeWhere(
        (session) => !session.isOpen && session.end!.isBefore(cutoff),
      );
      if (drop.isNotEmpty) this.revision++;
    });
    if (this.sessions.length != before) this._saveSessions();
    this._saveCoverage();
  }

  /// "Delete all data" in Settings: rows, bookkeeping and the relay
  /// session (the relay deletes what it kept for the channel).
  Future<void> deleteAllData() async {
    final token = this._relayToken;
    this._relayEpoch++;
    this._relayRetryTimer?.cancel();
    if (this._relayRunning) {
      this._relayRunning = false;
      await this._relayClient.stop();
    }
    if (token != null) unawaited(this._relayClient.unregister(token));
    this._relayToken = null;
    this._relayUserId = null;
    this._relayCursor = 0;
    await this.clearHistory();
    runInAction(() {
      this.sessions.clear();
      this.relayState = KickRelayState.off;
    });
    this._ledger.coverage.closeAll(this._clock());
    this._ledger.coverage.prune(this._clock().add(const Duration(days: 1)));

    await this._persistence.putMeta('sessions', null);
    await this._persistence.putMeta('coverage', null);
    await this._persistence.putMeta('heartbeat', null);
    this._saveState();

    /// Still listening: what is connected right now starts a new window
    this._nativeOpen.clear();
    for (final platform in ActivityPlatform.values) {
      this._applyNativeCoverage(platform);
    }
  }

  // Test seams

  /// Live flag of one source (tests: drive sessions without stores).
  void setLiveForTest(
    String source,
    bool live, {
    DateTime? since,
    DateTime? endedAt,
  }) => this._setLive(source, live, since: since, endedAt: endedAt);

  void setNativeCoverageForTest(ActivityPlatform platform, String? channel) =>
      this._setCoverer('test-${platform.name}', platform, channel);

  /// Run one 30 s tick now (tests: freeze detection, heartbeat).
  void tickForTest() => this._onTick();

  void pruneForTest() => this._prune();

  Future<void> dispose() async {
    this._ticker?.cancel();
    this._lifecycle?.dispose();
    for (final watch in this._boxWatches) {
      await watch.cancel();
    }
    this._boxWatches.clear();
    await this._youTubePoller.dispose();
    this._relayRetryTimer?.cancel();
    this._relayCursorWrite?.cancel();
    for (final disposer in this._reactions) {
      disposer();
    }
    this._reactions.clear();
    for (final subscription in this._subscriptions) {
      await subscription.cancel();
    }
    this._subscriptions.clear();
    await this._relayClient.stop();
  }
}
