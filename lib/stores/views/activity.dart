import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:mobx/mobx.dart';

import '../../models/kick_auth.dart';
import '../../models/twitch_auth.dart';
import '../../types/classes/activity/activity_event.dart';
import '../../types/enums/hive_keys.dart';
import '../../types/enums/settings_keys.dart';
import '../../utils/activity/activity_ledger.dart';
import '../../utils/activity/activity_mappers.dart';
import '../../utils/activity/activity_persistence.dart';
import '../../utils/general_helper.dart';
import '../../utils/kick/kick_events_relay_client.dart';
import '../pro_store.dart';
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
    bool attachPlatformStores = true,
  }) : _persistence = persistence ?? HiveActivityPersistence(),
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

  ActivityLedger _ledger = ActivityLedger();

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

  final List<ActivityEvent> _pending = [];
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final List<ReactionDisposer> _reactions = [];
  final Set<String> _attached = {};

  /// Native coverage per platform → channel id it is open for
  final Map<ActivityPlatform, String> _nativeCovered = {};
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
      GeneralHelper.advLog('Activity feed: could not open storage - $e');
    }
    runInAction(() => this.loaded = true);
    for (final event in List.of(this._pending)) {
      this._ingest(event);
    }
    this._pending.clear();
    this._prune();
    this._ticker = Timer.periodic(_tick, (_) => this._onTick());
    if (this._attachPlatformStores) {
      this._reactions.add(
        reaction<bool>((_) => this._isProResolver(), (pro) {
          if (pro) this._createSignedInStores();
          this._syncRelay();
        }, fireImmediately: true),
      );
      this.chatStoreCreated();
    }
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
    final coverage = ActivityCoverage.fromJson(
      this._persistence.loadMeta('coverage'),
    );

    /// Nothing is connected yet - a window left open by a kill must not
    /// claim the downtime
    coverage.closeAll(now);
    this._ledger = ActivityLedger(coverage: coverage, seq: seq);
    for (final event in this._persistence.loadEvents()) {
      this._ledger.restore(event);
    }

    final seen = this._persistence.loadMeta('seen');
    final rawSessions = this._persistence.loadMeta('sessions');
    final heartbeat = DateTime.tryParse(
      '${this._persistence.loadMeta('heartbeat')}',
    )?.toUtc();
    runInAction(() {
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

          /// Left open by a kill: it ended at the last heartbeat
          this.sessions.add(
            session.isOpen
                ? session.copyWith(end: heartbeat ?? session.start)
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
    if (!this._attached.contains('twitch') && _created<TwitchChatStore>()) {
      this._attached.add('twitch');
      this._attachTwitch(getIt<TwitchChatStore>());
    }
    if (!this._attached.contains('youtube') && _created<YouTubeChatStore>()) {
      this._attached.add('youtube');
      this._attachYouTube(getIt<YouTubeChatStore>());
    }
    if (!this._attached.contains('kick') && _created<KickChatStore>()) {
      this._attached.add('kick');
      this._attachKick(getIt<KickChatStore>());
    }
  }

  static bool _created<T extends Object>() {
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<T>()) return false;
    try {
      return getIt.checkLazySingletonInstanceExists<T>();
    } on StateError {
      return true;
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
      GeneralHelper.advLog('Activity feed: store start failed - $e');
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
            this._setNativeCoverage(ActivityPlatform.twitch, ownId);
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
    this._reactions.add(
      reaction<String?>(
        (_) =>
            youTube.isViewingOwnChannel &&
                youTube.chatConnection == YouTubeChatConnectionState.connected
            ? youTube.selfChannelId
            : null,
        (ownId) {
          this._setNativeCoverage(ActivityPlatform.youtube, ownId);

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
          (ownId) => this._setNativeCoverage(ActivityPlatform.kick, ownId),
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

  void _setNativeCoverage(ActivityPlatform platform, String? channelId) {
    final now = this._clock();
    final previous = this._nativeCovered[platform];
    if (previous == channelId) return;
    if (previous != null) {
      this._ledger.coverage.close(
        ActivitySource.native,
        platform,
        previous,
        now,
      );
      this._nativeCovered.remove(platform);
    }
    if (channelId != null) {
      this._ledger.coverage.open(
        ActivitySource.native,
        platform,
        channelId,
        now,
      );
      this._nativeCovered[platform] = channelId;
    }
    this._saveCoverage();
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
          'youtube' => ActivityPlatform.youtube,
          'kick' || 'kick-relay' => ActivityPlatform.kick,
          _ => null,
        },
    };
    final last = this.sessions.isEmpty ? null : this.sessions.first;

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
        this.sessions[0] = last.copyWith(
          clearEnd: true,
          platforms: {...last.platforms, ...platforms},
          start: since != null && since.isBefore(last.start) ? since : null,
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
    this.revision++;
  }

  void _onTick() {
    this._ticks++;

    /// OBS streaming counts as live too (no platform needed)
    final obsLive =
        _created<DashboardStore>() && GetIt.instance<DashboardStore>().isLive;
    this._setLive('obs', obsLive);
    if (this.currentSession != null) {
      unawaited(
        this._persistence.putMeta(
          'heartbeat',
          this._clock().toUtc().toIso8601String(),
        ),
      );
    }

    /// Every 6 h while running
    if (this._ticks % 720 == 0) this._prune();
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
    this.markAllSeen();
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

  @action
  void setFilter(ActivityFilter filter) => this.filter = filter;

  @action
  void setToThankOnly(bool value) => this.toThankOnly = value;

  /// Forget every row (sessions and coverage stay).
  @action
  Future<void> clearHistory() async {
    final ids = this._ledger.events.map((e) => e.id).toList();
    for (final id in ids) {
      this._ledger.remove(id);
    }
    this.seenMarks.clear();
    this.visitMarks = null;
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
        token = session.token;
        this._relayToken = session.token;
        this._relayUserId = session.broadcasterUserId;
        this._relayCursor = 0;
        this._relayRegisterFailedAt = null;
        this._saveState();
      } catch (e) {
        GeneralHelper.advLog('Kick relay sign-in failed - $e');
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

  void _relayCoverage(bool synced) {
    final channel = this._relayUserId;
    if (channel == null) return;
    final now = this._clock();
    final changed = synced
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
      final (channel, live, at) = status;
      if (channel == this._relayUserId) {
        this._setLive(
          'kick-relay',
          live,
          since: live ? at : null,
          endedAt: live ? null : at,
        );
      }
      return;
    }
    final event = kickActivityFromRelay(frame);
    if (event != null) runInAction(() => this.ingest(event));
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

  void _saveCoverage() => unawaited(
    this._persistence.putMeta('coverage', this._ledger.coverage.toJson()),
  );

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
      this._setNativeCoverage(platform, channel);

  void pruneForTest() => this._prune();

  Future<void> dispose() async {
    this._ticker?.cancel();
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
