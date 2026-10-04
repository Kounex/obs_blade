import 'dart:async';
import 'dart:collection';

import 'package:hive_ce/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/stores/shared/chat_buffer_cap.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/models/youtube_auth.dart';
import 'package:obs_blade/stores/pro_store.dart';
import 'package:obs_blade/stores/views/combined_chat.dart';
import 'package:obs_blade/types/classes/combined/combined_combo.dart';
import 'package:obs_blade/types/classes/activity/activity_event.dart';
import 'package:obs_blade/types/classes/chat/chat_ban_entry.dart';
import 'package:obs_blade/types/classes/youtube/youtube_chat_message.dart';
import 'package:obs_blade/types/classes/youtube/youtube_token.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/stores/views/youtube_emojis.dart';
import 'package:obs_blade/utils/activity/activity_mappers.dart';
import 'package:obs_blade/utils/general_helper.dart';
import 'package:obs_blade/utils/youtube/youtube_auth_service.dart';
import 'package:obs_blade/utils/youtube/youtube_channel_search_service.dart';
import 'package:obs_blade/utils/youtube/youtube_entry_name.dart';
import 'package:obs_blade/utils/youtube/youtube_live_chat_service.dart';
import 'package:obs_blade/utils/youtube/youtube_live_resolver.dart';
import 'package:obs_blade/utils/youtube_target.dart';

part 'youtube_chat.g.dart';

enum YouTubeAuthState {
  /// No API key resolves — native YouTube chat can't read anything, so
  /// sign-in isn't offered either.
  unconfigured,
  signedOut,
  requestingCode,
  awaitingAuthorization,
  signingIn,
  signedIn,
  error,
}

enum YouTubeChatConnectionState {
  /// No selected channel (or not started yet).
  idle,
  connecting,
  connected,

  /// The video has no active live chat / the chat ended — not an error.
  offline,
  error,
}

/// YouTube chat messages are at most 200 characters - the limit YouTube's
/// own chat input enforces. The API reference doesn't state one; longer
/// text is answered `messageTextInvalid` (community reports, unverified
/// here), so the app stops it before sending.
const int kYouTubeChatMessageMaxLength = 200;

class YouTubeChatStore = _YouTubeChatStore with _$YouTubeChatStore;

/// Channel entries re-check for a (new) live stream on this escalating
/// schedule while nothing is live; the last step repeats. The check is
/// free (page scrape, a few KB) — only a found watch id spends the
/// 1-unit `videos.list`.
const List<Duration> kYouTubeLiveRecheckSchedule = [
  Duration(seconds: 20),
  Duration(seconds: 30),
  Duration(seconds: 60),
  Duration(seconds: 90),
];

/// The next YouTube Data API quota reset after [now]: midnight Pacific
/// time (07:00 UTC while US daylight saving time is on, 08:00 UTC
/// otherwise; DST runs from the second Sunday of March to the first
/// Sunday of November - at local midnight of both switch days the old
/// offset still applies).
DateTime nextYouTubeQuotaReset(DateTime now) {
  final utc = now.toUtc();
  DateTime nthSunday(int year, int month, int n) {
    final first = DateTime.utc(year, month, 1);
    final offset = (DateTime.sunday - first.weekday) % 7;
    return DateTime.utc(year, month, 1 + offset + 7 * (n - 1));
  }

  bool dstAtMidnight(DateTime day) {
    final start = nthSunday(day.year, DateTime.march, 2);
    final end = nthSunday(day.year, DateTime.november, 1);
    return day.isAfter(start) && !day.isAfter(end);
  }

  for (var d = -1; d <= 2; d++) {
    final day = DateTime.utc(utc.year, utc.month, utc.day + d);
    final reset = DateTime.utc(
      day.year,
      day.month,
      day.day,
      dstAtMidnight(day) ? 7 : 8,
    );
    if (reset.isAfter(utc)) return reset;
  }
  return utc.add(const Duration(days: 1));
}

/// YouTube's answer for "not the owner / a moderator here" - a 403 (a 401
/// is a rejected token, not a role).
bool _isNotModerator(YouTubeApiException e) =>
    e is YouTubeForbiddenException && e.statusCode != 401;

/// Grace after the quota reset before the chat restarts on its own.
const Duration kYouTubeQuotaResetGrace = Duration(minutes: 1);

/// How one resolve-and-poll pass of the read transport ended.
enum _PassOutcome {
  /// Nothing live (or the chat ended before any page arrived).
  offline,

  /// A chat connected and has since ended — resets the recheck backoff.
  attached,

  /// Terminal (error / quota / superseded) — the loop exits.
  stopped,

  /// Transient failure before the chat attached (network drop, 5xx) —
  /// the loop backs off and runs the pass again.
  retry,
}

/// Whether a read failure clears up on its own: the socket iOS kills
/// while the app is backgrounded, timeouts, 5xx. A 4xx is YouTube's
/// definitive answer (bad key, chat disabled, not found) and needs the
/// user; an [Error] is a bug, not a network state.
bool _isTransientReadFailure(Object e) {
  if (e is YouTubeApiException) {
    final status = e.statusCode;
    return status == null || status == 408 || status >= 500;
  }
  return e is Exception;
}

/// One entry of the native YouTube channel list — derived from the
/// [SettingsKeys.YouTubeUsernames] map (label → raw value; [target] is
/// parsed out of the raw value via [parseYouTubeTarget]). A channel target
/// resolves its current live stream at connect time and rolls over to the
/// next stream on its own; a video target is pinned to that one video.
class YouTubeChatChannel {
  final String label;
  final YouTubeTarget target;

  /// The signed-in account's own channel (the native "You" entry) — its
  /// [label] is [kYouTubeOwnChannelLabel], never a settings map key.
  final bool isOwn;

  /// Display name for the own entry (the channel title); user entries
  /// show their [label].
  final String? title;

  const YouTubeChatChannel({
    required this.label,
    required this.target,
    this.isOwn = false,
    this.title,
  });

  /// What the channel pickers show.
  String get displayName =>
      this.isOwn ? (this.title ?? 'Own channel') : this.label;

  /// The pinned video id — null for channel entries (their video is
  /// resolved per stream).
  String? get videoId => switch (this.target) {
    YouTubeVideoTarget(:final videoId) => videoId,
    YouTubeChannelTarget() => null,
  };

  bool get isChannel => this.target is YouTubeChannelTarget;
}

/// Reserved [YouTubeChatChannel.label] of the own-channel entry. Starts
/// with a NUL so no typed entry name can collide with it; persisted as
/// [SettingsKeys.SelectedYouTubeNativeChannelId] like any other label.
const String kYouTubeOwnChannelLabel = '\u0000own';

/// How often a connected YouTube chat re-reads its viewer count (one
/// `videos.list` unit each, ~120/h — about 3% on top of the chat poll)
/// so the LIVE chips follow the stream.
const Duration kViewerRefreshInterval = Duration(seconds: 30);

/// Send refusals while not attached to a live chat — cleared again once
/// the chat attaches.
const String _kSendNoStreamText = 'No live stream to send to right now';
const String _kSendNotConnectedText =
    'Chat is not connected - try again in a moment';

/// In-memory per-channel chat snapshot — swapped in/out of the live
/// [messages] list on selectChannel so switching back restores recent
/// history and the poll resumes from [nextPageToken] without re-resolving
/// [liveChatId]. Dies with the app session; never persisted (chat content
/// never touches Hive).
class _ChannelBuffer {
  List<YouTubeChatMessage> messages;
  String? liveChatId;
  String? nextPageToken;

  /// Video the current [liveChatId] belongs to (resolved per stream for
  /// channel entries).
  String? videoId;

  /// Channel broadcasting [videoId] (its member emojis work here)
  String? channelId;

  /// Last video whose chat ended — a channel's `/live` page can keep
  /// pointing at the finished stream for a while, so re-resolving to it
  /// counts as "not live yet" without spending a `videos.list` unit.
  String? endedVideoId;

  /// Snapshot taken when [liveChatId] was resolved — not re-polled
  /// afterward (see [YouTubeLiveStreamingDetails]).
  int? viewerCount;

  List<ChatBanEntry> bans = <ChatBanEntry>[];
  YouTubeChatMessage? activePoll;

  /// Earliest time the next `liveChatMessages.list` may go out (the last
  /// page's `pollingIntervalMillis` after it arrived) - a poll resumed by
  /// a channel switch back / un-pause / app resume waits out the rest
  /// instead of answering `rateLimitExceeded`.
  DateTime? nextPollAt;

  _ChannelBuffer({
    List<YouTubeChatMessage>? messages,
    this.liveChatId,
    this.nextPageToken,
    this.viewerCount,
  }) : messages = messages ?? <YouTubeChatMessage>[];
}

/// Owns the native YouTube chat: API-key gated reads, device-flow sign-in
/// state, the persisted [YouTubeAuth] record and the
/// `liveChatMessages.list` poll loop with per-channel buffers.
abstract class _YouTubeChatStore with Store {
  static const int kMaxMessages = 500;

  /// The selected channel's cap - raised while a reader is scrolled up
  /// in it ([holdScrollback]); background channel buffers keep 500
  final ChatBufferCap messageCap = ChatBufferCap(base: kMaxMessages);

  /// A reader scrolled up in the chat: stop dropping the oldest rows
  /// under them ([ChatBufferCap]). Pair with [releaseScrollback].
  void holdScrollback() => this.messageCap.hold();

  /// The reader is back at the newest row: trim back to 500.
  void releaseScrollback() {
    if (!this.messageCap.release()) return;
    runInAction(() {
      while (this.messages.length > this.messageCap.value) {
        this.messages.removeAt(0);
      }
    });
  }
  static const Duration kRefreshWindow = Duration(minutes: 5);

  /// Backoff ceiling — rate limiting and transient read failures double
  /// the wait per hit, capped here.
  static const int kMaxBackoffMillis = 60000;

  /// First wait after a transient failure before the chat attached.
  static const int kInitialRetryMillis = 2000;

  final YouTubeAuthService _authService;
  final YouTubeLiveChatService _chatService;
  final YouTubeLiveResolver _liveResolver;

  /// Injectable delay for the poll loop — unit tests pass an instant
  /// sleeper (and record the durations) instead of really waiting.
  final Future<void> Function(Duration) _sleep;

  StreamSubscription<BoxEvent>? _authBoxSub;
  bool _loginCancelled = false;

  /// Identifies the active login flow — a superseded flow's stale
  /// continuations (e.g. a poll still mid-sleep) must not touch state.
  int _loginFlow = 0;

  /// Identifies the active poll loop — selectChannel/dispose bump this so
  /// a stale loop's continuations (mid-sleep or mid-request) bail out.
  int _pollFlow = 0;

  /// Whether [_loadChannelsFromSettings] already ran for this instance —
  /// the settings load is idempotent per store instance.
  bool _channelsLoaded = false;

  /// Pro entitlement read (test seam) - native chat "just doesn't work"
  /// without Pro: [connectChat] refuses, so neither a persisted engine
  /// selection nor the cold-start auto-select can start polling behind
  /// the locked pane.
  final bool Function() _isProResolver;

  /// How often a connected chat re-reads its viewer count (tests: zero).
  final Duration _viewerRefreshInterval;

  /// Wall clock (test seam) - poll pacing and the quota reset.
  final DateTime Function() _now;

  /// Restarts the chat after the daily quota reset ([quotaResetAt]).
  Timer? _quotaResetTimer;

  /// When the used-up quota comes back (set while [chatQuotaExhausted]).
  DateTime? quotaResetAt;

  _YouTubeChatStore({
    YouTubeAuthService? authService,
    YouTubeLiveChatService? chatService,
    YouTubeLiveResolver? liveResolver,
    Future<void> Function(Duration)? sleep,
    bool Function()? isProResolver,
    Duration viewerRefreshInterval = kViewerRefreshInterval,
    DateTime Function()? now,
  }) : _viewerRefreshInterval = viewerRefreshInterval,
       _now = now ?? DateTime.now,
       _authService = authService ?? YouTubeAuthService(),
       _chatService = chatService ?? YouTubeLiveChatService(),
       _liveResolver = liveResolver ?? YouTubeLiveResolver(),
       _sleep = sleep ?? Future.delayed,
       _isProResolver =
           isProResolver ?? (() => GetIt.instance<ProStore>().isPro);

  Box<YouTubeAuth> get _authBox =>
      Hive.box<YouTubeAuth>(HiveKeys.YouTubeAuth.name);

  @observable
  YouTubeAuthState authState = YouTubeAuthState.unconfigured;

  @observable
  String? authError;

  @observable
  String? pendingUserCode;

  @observable
  String? pendingVerificationUrl;

  @observable
  YouTubeChatConnectionState chatConnection = YouTubeChatConnectionState.idle;

  /// Live preview per channel entry for the pickers (label → live?),
  /// from the quota-free `/live` page check ([refreshChannelLivePreviews]).
  /// Absent = unknown (not checked yet, lookup failed, a pinned video).
  final ObservableMap<String, bool> channelLivePreview =
      ObservableMap<String, bool>();

  DateTime? _livePreviewAt;

  /// Picker live state of [label]: true / false once checked, null before.
  /// The selected entry answers from its connection instead (connected =
  /// live, waiting for a stream = offline).
  bool? liveStateForChannel(String label) {
    if (label == this.selectedChannelLabel) {
      if (this.chatConnection == YouTubeChatConnectionState.connected) {
        return true;
      }
      if (this.awaitingLiveStream) return false;
    }
    return this.channelLivePreview[label];
  }

  /// Check every channel entry's live state — run when a picker opens,
  /// at most once a minute ([force] skips that). No API quota: one
  /// `/live` page fetch per channel entry; pinned videos are skipped.
  Future<void> refreshChannelLivePreviews({bool force = false}) async {
    if (!this._isProResolver()) return;
    final now = DateTime.now();
    final last = this._livePreviewAt;
    if (!force && last != null && now.difference(last).inSeconds < 60) {
      return;
    }
    this._livePreviewAt = now;
    final entries = [
      for (final channel in this.nativeChannels)
        if (channel.target case final YouTubeChannelTarget target)
          (channel.label, target),
    ];
    await Future.wait([
      for (final (label, target) in entries)
        this._liveResolver
            .resolveLiveVideoId(target)
            .then((videoId) {
              runInAction(
                () => this.channelLivePreview[label] = videoId != null,
              );
            })
            .catchError((Object e) {
              GeneralHelper.logFailure(
                'YouTube live preview failed for $label',
                e,
              );
            }),
    ]);
    runInAction(() {
      final labels = {for (final (label, _) in entries) label};
      this.channelLivePreview.removeWhere(
        (label, _) => !labels.contains(label),
      );
    });
  }

  /// Concurrent-viewer snapshot for [selectedChannelLabel] — resolved
  /// once alongside `activeLiveChatId` (see [_ChannelBuffer.viewerCount]);
  /// not re-polled while connected.
  @observable
  int? selectedChannelViewerCount;

  @observable
  String? chatError;

  /// A channel entry is between streams — [chatConnection] is `offline`
  /// and the store keeps re-checking for the next live stream on
  /// [kYouTubeLiveRecheckSchedule] (see [recheckLiveNow] to skip the wait).
  @observable
  bool awaitingLiveStream = false;

  /// Video the selected entry's chat is attached to right now (the pinned
  /// id for video entries, the resolved stream for channel entries).
  @observable
  String? selectedLiveVideoId;

  /// Channel broadcasting [selectedLiveVideoId] - whose member emojis the
  /// picker offers. Plain read (the picker reads it when it opens).
  String? get selectedLiveChannelId => this.selectedLiveVideoId == null
      ? null
      : this._channelBuffers[this.selectedChannelLabel]?.channelId;

  /// Ids of messages we sent, shown from the insert answer until the poll
  /// delivers YouTube's own copy (removed then) - one id per own message
  final Set<String> _localEchoIds = {};

  /// The emoji catalog, when registered (tests without it skip emojis)
  YouTubeEmojiStore? get _emojis =>
      GetIt.instance.isRegistered<YouTubeEmojiStore>()
      ? GetIt.instance<YouTubeEmojiStore>()
      : null;

  /// True after a [YouTubeQuotaExceededException] stopped the poll loop —
  /// polling restarts on its own after the midnight-PT quota reset
  /// ([quotaResetAt]; a timer, or the next app resume when the timer was
  /// suspended) or on a manual retry.
  @observable
  bool chatQuotaExhausted = false;

  /// A send is in flight — drives the dock's disabled/spinner state and
  /// guards against concurrent sends.
  @observable
  bool sendingChat = false;

  /// Transient send failure for the dock's error line; cleared on the next
  /// attempt.
  @observable
  String? sendChatError;

  /// Transient moderation failure (delete / ban / unban) the UI toasts;
  /// cleared on the next mod action.
  @observable
  String? moderationError;

  /// The last mod action came back 403 — YouTube's answer when the
  /// account isn't the owner / a moderator here. The UI explains it.
  @observable
  bool moderationForbidden = false;

  /// Bans / timeouts seen in the selected chat this session (issued here
  /// or echoed as `userBannedEvent`), newest first — YouTube has no
  /// ban-list API. Only entries with a [ChatBanEntry.banId] (issued here)
  /// can be lifted.
  final ObservableList<ChatBanEntry> recentBans =
      ObservableList<ChatBanEntry>();

  /// The chat's active poll (`activePollItem` of the last poll page).
  @observable
  YouTubeChatMessage? activePoll;

  /// Moderators of the selected chat — owner-only
  /// ([loadModerators]); null until loaded.
  @observable
  ObservableList<YouTubeChatModerator>? moderators;

  /// Whether the signed-in account owns the selected chat — the only
  /// case the moderator list works.
  bool get isViewingOwnChannel => this.isOwnChannel(this.selectedChannelLabel);

  /// Native YouTube channels derived from [SettingsKeys.YouTubeUsernames]
  /// (label → raw value; entries whose value parses to neither a channel
  /// nor a video via [parseYouTubeTarget] are skipped).
  final ObservableList<YouTubeChatChannel> channels =
      ObservableList<YouTubeChatChannel>();

  /// The signed-in account's own channel (the native "You" entry, always
  /// first in [nativeChannels]) — null while signed out or before the
  /// channel id is known. Native-only: never written into
  /// [SettingsKeys.YouTubeUsernames].
  @observable
  YouTubeChatChannel? ownChannel;

  /// Signed in, but YouTube answered "no channel" for the account (a
  /// Brand Account channel's owner picked as the personal account at
  /// Google's account step) - no "You" entry and nothing to write as.
  /// Not set when the lookup failed (that retries on the next launch).
  @observable
  bool signedInWithoutChannel = false;

  /// [signedInWithoutChannel], mirrored to the settings box: the activity
  /// feed's status banner reads it without creating this store (that
  /// would start a poll).
  void _setNoChannel(bool value) {
    this.signedInWithoutChannel = value;
    try {
      if (Hive.isBoxOpen(HiveKeys.Settings.name)) {
        Hive.box(
          HiveKeys.Settings.name,
        ).put(SettingsKeys.YouTubeSignedInWithoutChannel.name, value);
      }
    } catch (_) {}
  }

  /// The native channel list: [ownChannel] first, then the added
  /// [channels].
  @computed
  List<YouTubeChatChannel> get nativeChannels => [
    ?this.ownChannel,
    ...this.channels,
  ];

  /// Whether [label] is the signed-in account's own channel entry.
  bool isOwnChannel(String? label) =>
      label == kYouTubeOwnChannelLabel && this.ownChannel != null;

  /// Currently viewed channel — the **label** (map key of
  /// [SettingsKeys.YouTubeUsernames], stable across re-edits, or
  /// [kYouTubeOwnChannelLabel]), persisted as
  /// [SettingsKeys.SelectedYouTubeNativeChannelId]. Null = no selection.
  @observable
  String? selectedChannelLabel;

  /// Per-channel chat snapshots keyed by label (in-memory only).
  final Map<String, _ChannelBuffer> _channelBuffers =
      <String, _ChannelBuffer>{};

  /// Recently applied moderation keys (tombstones / ban purges) — local
  /// mod actions tombstone immediately and the poll echo must not
  /// double-apply. Bounded FIFO, oldest keys evicted.
  static const int _kMaxAppliedModerationKeys = 256;
  final Set<String> _appliedModerationKeys = <String>{};
  final Queue<String> _appliedModerationOrder = Queue<String>();

  final ObservableList<YouTubeChatMessage> messages =
      ObservableList<YouTubeChatMessage>();

  /// Whether a YouTube Data API key resolves non-empty (BYO setting wins
  /// over the app-owned constant). Gates the whole feature.
  bool get isConfigured => YouTubeLiveChatService.resolveApiKey().isNotEmpty;

  /// Reads (polling) need only the API key — no sign-in required.
  bool get canRead => this.isConfigured;

  /// Sign-in (writing, moderating, the own "You" chat) needs an OAuth
  /// client on top of the API key - without one the chat stays read-only.
  bool get canSignIn => this._authService.resolveClientId().isNotEmpty;

  @computed
  bool get isSignedInState => this.authState == YouTubeAuthState.signedIn;

  /// Whether the persisted token is usable for writes: present, carrying
  /// the YouTube scope, and either unexpired or backed by a refresh token
  /// (every write refreshes a due token first). Deliberately a plain
  /// getter (not reactive): the record changes only at sign-in/sign-out,
  /// which flips [authState] and rebuilds observers.
  bool get isSignedIn {
    final auth = this._authBox.get(YouTubeAuth.kBoxKey);
    return auth != null &&
        (auth.refreshToken.isNotEmpty || !auth.isExpired) &&
        kYouTubeChatScopes.every(auth.scopes.contains);
  }

  /// Writes (send / delete / ban) require a signed-in, scoped token of an
  /// account that has a channel - a channel-less Google account has
  /// nothing to write or moderate as ([signedInWithoutChannel]).
  bool get canWrite => this.isSignedIn && !this.signedInWithoutChannel;

  /// Who the session is, for "Connected as …" copy.
  String get accountDescription =>
      this.selfChannelTitle ??
      (this.signedInWithoutChannel
          ? 'a Google account without a YouTube channel'
          : 'your YouTube channel');

  /// Title of the signed-in channel (display only).
  String? get selfChannelTitle =>
      this._authBox.get(YouTubeAuth.kBoxKey)?.channelTitle;

  /// `UC…` id of the signed-in channel.
  String? get selfChannelId =>
      this._authBox.get(YouTubeAuth.kBoxKey)?.channelId;

  /// Max recent lines shown on the native chat user card.
  static const int kUserCardMessageCap = 20;

  /// Messages from [channelId] in the current channel buffer, newest
  /// first (capped at [kUserCardMessageCap]).
  List<YouTubeChatMessage> messagesForChatter(String channelId) {
    final matches = <YouTubeChatMessage>[
      for (final message in this.messages)
        if (message.authorChannelId == channelId) message,
    ];
    final start = matches.length > kUserCardMessageCap
        ? matches.length - kUserCardMessageCap
        : 0;
    return matches.sublist(start).reversed.toList();
  }

  /// Public channel facts (creation date) for the user card —
  /// 1 quota unit, on demand only, works without sign-in (plain API-key
  /// read). Null on any failure so the card can hide the section
  /// instead of erroring.
  Future<YouTubeChannelInfo?> fetchChannelInfo(String channelId) async {
    if (!this.isConfigured) return null;
    try {
      return await this._chatService.fetchChannel(
        channelId,
        apiKey: YouTubeLiveChatService.resolveApiKey(),
      );
    } catch (e) {
      GeneralHelper.logFailure('YouTube channel fetch failed', e);
      return null;
    }
  }

  /// Target of the selected entry, if it still exists in settings.
  YouTubeTarget? get _selectedTarget {
    final label = this.selectedChannelLabel;
    if (label == null) return null;
    for (final channel in this.nativeChannels) {
      if (channel.label == label) return channel.target;
    }
    return null;
  }

  /// The selected entry, if it still exists in settings.
  YouTubeChatChannel? get selectedChannel {
    final label = this.selectedChannelLabel;
    if (label == null) return null;
    for (final channel in this.nativeChannels) {
      if (channel.label == label) return channel;
    }
    return null;
  }

  /// Registers the box watcher (idempotent) so external wipes — e.g.
  /// data management clearing the YouTube box — reset the feature even
  /// when [init] never ran for this instance.
  void _ensureAuthBoxWatcher() {
    this._authBoxSub ??= this._authBox.watch(key: YouTubeAuth.kBoxKey).listen((
      event,
    ) {
      if (event.deleted && this.authState != YouTubeAuthState.signedOut) {
        this._resetToSignedOut();
      }
    });
  }

  /// Cold start: restore channels + selection, then pick up a stored
  /// session. YouTube has no cheap token-validation endpoint — a stored
  /// record is trusted until a call 401/403s it.
  @action
  Future<void> init() async {
    this._ensureAuthBoxWatcher();
    this._ensureChannelsLoaded();

    if (!this.isConfigured) {
      this.authState = YouTubeAuthState.unconfigured;
      return;
    }

    final auth = this._authBox.get(YouTubeAuth.kBoxKey);
    if (auth == null) {
      this.authState = YouTubeAuthState.signedOut;
      this._syncOwnChannel();
      this._autoSelectChannel();
      return;
    }

    try {
      await this._validAccessToken();
    } on YouTubeAuthException catch (e) {
      /// Wipe the stored session only on a definitive auth failure — a
      /// 400 (`invalid_grant`) / 401 / 403 on refresh means the refresh
      /// token is dead; a null status is our own pre-flight throw.
      /// Anything else (transient 5xx, offline) keeps the session.
      if (e.statusCode == null ||
          e.statusCode == 400 ||
          e.statusCode == 401 ||
          e.statusCode == 403) {
        await this._handleInvalidAuth(
          'YouTube session expired - please sign in again',
        );

        /// Reads need only the API key — same as having no session. A
        /// kept selection already started reading again.
        if (this.selectedChannelLabel == null) this._autoSelectChannel();
        return;
      }

      /// Transient 5xx: the record stays usable — the next write
      /// refreshes again — and reads need only the API key.
      GeneralHelper.logFailure('YouTube token refresh on init failed', e);
    } catch (e) {
      /// Offline at launch (no HTTP answer at all) — same as a 5xx.
      /// Letting it escape left the store `unconfigured` with no poll.
      GeneralHelper.logFailure('YouTube token refresh on init failed', e);
    }
    this.authState = YouTubeAuthState.signedIn;
    this._syncOwnChannel();
    if (auth.channelId == null) {
      unawaited(this._backfillOwnChannel());
    }
    this._autoSelectChannel();
  }

  /// Sessions persisted before [YouTubeAuth.channelId] existed fetch it
  /// once on restore (1 quota unit); the entry appears when it lands.
  Future<void> _backfillOwnChannel() async {
    try {
      final token = await this._validAccessToken();
      final own = await this._authService.fetchOwnChannel(token);
      runInAction(() => this._setNoChannel(own == null));
      final current = this._authBox.get(YouTubeAuth.kBoxKey);
      if (own == null || current == null) return;
      current
        ..channelId = own.id
        ..channelTitle = own.title ?? current.channelTitle;
      await current.save();
      this._syncOwnChannel();
    } catch (e) {
      GeneralHelper.logFailure('YouTube own channel backfill failed', e);
    }
  }

  /// Mirror the stored session's channel into [ownChannel]. A selected own
  /// entry that no longer exists (signed out, wiped session) falls back to
  /// the first added entry (or none) — the dropdown can't show a vanished
  /// value.
  void _syncOwnChannel() {
    final auth = this.authState == YouTubeAuthState.signedIn
        ? this._authBox.get(YouTubeAuth.kBoxKey)
        : null;
    final channelId = auth?.channelId;
    final target = channelId == null ? null : parseYouTubeTarget(channelId);
    runInAction(() {
      this.ownChannel = target == null
          ? null
          : YouTubeChatChannel(
              label: kYouTubeOwnChannelLabel,
              target: target,
              isOwn: true,
              title: auth?.channelTitle,
            );
    });
    if (this.selectedChannelLabel == kYouTubeOwnChannelLabel &&
        this.ownChannel == null) {
      unawaited(this.selectChannel(this.channels.firstOrNull?.label));
    }
    if (this.ownChannel case final own?) this._dropOwnComboCopies(own);
  }

  /// Saved combos used to add the own channel to the channel list as a
  /// plain copy (no "You": no activity feed rows, no owner-only tools).
  /// Combos now open the "You" entry - the copies go, a selection or
  /// combined restore point on one moves to "You".
  void _dropOwnComboCopies(YouTubeChatChannel own) {
    try {
      final box = Hive.box(HiveKeys.Settings.name);
      final getIt = GetIt.instance;
      final combinedCreated =
          getIt.isRegistered<CombinedChatStore>() &&
          getIt.checkLazySingletonInstanceExists<CombinedChatStore>();
      final combosRaw = box.get(SettingsKeys.CombinedChatCombos.name);
      final raw = box.get(SettingsKeys.YouTubeUsernames.name);
      final copies = raw is Map
          ? ownYouTubeComboCopies(
              raw,
              parseCombinedCombos(combosRaw),
              own,
              webViewSelected: box.get(
                SettingsKeys.SelectedYouTubeUsername.name,
              ),
            )
          : const <String>[];

      final marked = markOwnYouTubeComboSources(combosRaw, own);
      if (marked != null) {
        box.put(SettingsKeys.CombinedChatCombos.name, marked);
        if (combinedCreated) getIt<CombinedChatStore>().reloadCombos();
      }
      if (raw is! Map || copies.isEmpty) return;
      box.put(SettingsKeys.YouTubeUsernames.name, <String, String>{
        for (final MapEntry(:key, :value) in raw.entries)
          if (key is String && value is String && !copies.contains(key))
            key: value,
      });
      final selected = this.selectedChannelLabel;
      for (final copy in copies) {
        if (combinedCreated) {
          getIt<CombinedChatStore>().renameYouTubeRestore(
            copy,
            kYouTubeOwnChannelLabel,
          );
        }
      }
      this.reloadChannels();
      if (selected != null && copies.contains(selected)) {
        unawaited(this.selectChannel(kYouTubeOwnChannelLabel));
      }
    } catch (e) {
      GeneralHelper.logFailure('YouTube combo copy cleanup failed', e);
    }
  }

  /// Select the persisted channel (or the first configured one) and start
  /// polling — no-op without a readable configuration.
  void _autoSelectChannel() {
    if (this.selectedChannelLabel == null && this.nativeChannels.isNotEmpty) {
      unawaited(this.selectChannel(this.nativeChannels.first.label));
    } else if (this.selectedChannelLabel != null) {
      this.connectChat();
    }
  }

  @action
  Future<void> startLogin() async {
    if (!this.isConfigured) {
      this.authState = YouTubeAuthState.unconfigured;
      return;
    }
    if (this._authService.resolveClientId().isEmpty) {
      this.authState = YouTubeAuthState.error;
      this.authError = 'No Google OAuth client id configured';
      return;
    }
    this._loginCancelled = false;
    this._setNoChannel(false);
    final flow = ++this._loginFlow;
    this._ensureAuthBoxWatcher();
    this.authError = null;
    this.pendingUserCode = null;
    this.pendingVerificationUrl = null;
    this.authState = YouTubeAuthState.requestingCode;

    try {
      final deviceCode = await this._authService.requestDeviceCode();
      this.pendingUserCode = deviceCode.userCode;
      this.pendingVerificationUrl = deviceCode.verificationUrl;
      this.authState = YouTubeAuthState.awaitingAuthorization;

      final token = await this._authService.pollForToken(
        deviceCode,
        onPending: () {},
        isCancelled: () => this._loginCancelled || flow != this._loginFlow,
      );

      // A superseded flow must not write state — its stale continuation
      // resumes here before the next isCancelled check would run.
      if (flow != this._loginFlow) return;

      this.authState = YouTubeAuthState.signingIn;

      /// The own channel feeds the "You" entry + display — a fetch
      /// failure must not fail the sign-in.
      YouTubeOwnChannel? ownChannel;
      var channelLookedUp = false;
      try {
        ownChannel = await this._authService.fetchOwnChannel(token.accessToken);
        channelLookedUp = true;
      } catch (e) {
        GeneralHelper.logFailure('YouTube own channel fetch failed', e);
      }
      await this._persistAuth(token, ownChannel);
      this.pendingUserCode = null;
      this.pendingVerificationUrl = null;

      /// Before signedIn: the sign-in dialog reads both in the same frame
      this._setNoChannel(channelLookedUp && ownChannel == null);
      if (this.signedInWithoutChannel) {
        GeneralHelper.logFailure(
          'YouTube sign-in without a channel',
          'channels.list mine=true returned no channel - personal account '
              'picked for a Brand Account channel?',
        );
      }
      this.authState = YouTubeAuthState.signedIn;
      this._ensureChannelsLoaded();
      this._syncOwnChannel();

      /// Signing in with nothing selected lands on the own chat — the
      /// same default the Twitch engine has.
      if (this.selectedChannelLabel == null && this.ownChannel != null) {
        unawaited(this.selectChannel(kYouTubeOwnChannelLabel));
      } else {
        this.connectChat();
      }
    } on YouTubeAuthException catch (e) {
      // A superseded flow must not clobber the new flow's state.
      if (flow != this._loginFlow) return;
      this.pendingUserCode = null;
      if (this._loginCancelled) {
        this.authState = this._authBox.get(YouTubeAuth.kBoxKey) != null
            ? YouTubeAuthState.signedIn
            : YouTubeAuthState.signedOut;
      } else {
        this.authState = YouTubeAuthState.error;
        this.authError = e.message;
      }
    } catch (e) {
      if (flow != this._loginFlow) return;
      GeneralHelper.logFailure('YouTube login failed unexpectedly', e);
      this.pendingUserCode = null;
      this.authState = YouTubeAuthState.error;
      this.authError = 'Unexpected login error';
    }
  }

  @action
  void cancelLogin() {
    this._loginCancelled = true;
  }

  @action
  Future<void> logout() async {
    // Supersede any in-flight login flow so its stale continuations bail.
    this._loginFlow++;
    final auth = this._authBox.get(YouTubeAuth.kBoxKey);
    this._setNoChannel(false);
    this._stopPolling();
    this.messages.clear();
    this._channelBuffers.clear();
    this._appliedModerationKeys.clear();
    this._appliedModerationOrder.clear();
    this.authState = this.isConfigured
        ? YouTubeAuthState.signedOut
        : YouTubeAuthState.unconfigured;
    final wasOwn = this.selectedChannelLabel == kYouTubeOwnChannelLabel;
    this._syncOwnChannel();
    this._resumeReadingSignedOut(wasOwn: wasOwn);
    await this._authBox.delete(YouTubeAuth.kBoxKey);
    if (auth != null) {
      await this._authService.revoke(auth.accessToken);
    }
  }

  /// (Re)start the poll loop for the selected channel — called after
  /// init/sign-in and by the UI retry action. Hard entitlement gate:
  /// without Pro the native engine never comes up, no matter which entry
  /// point asks (persisted engine selection, cold-start auto-select, UI
  /// retry).
  @action
  void connectChat() {
    if (!this.canRead) return;
    if (!this._isProResolver()) return;
    if (this.selectedChannelLabel == null) {
      this.chatConnection = YouTubeChatConnectionState.idle;
      return;
    }
    this._restartPolling();
  }

  void _restartPolling() {
    final label = this.selectedChannelLabel;
    if (label == null) return;
    final flow = ++this._pollFlow;
    this.chatConnection = YouTubeChatConnectionState.connecting;
    this.awaitingLiveStream = false;
    this.chatError = null;
    this._clearQuotaStop();
    unawaited(this._pollLoop(label, flow));
  }

  void _clearQuotaStop() {
    this._quotaResetTimer?.cancel();
    this._quotaResetTimer = null;
    this.quotaResetAt = null;
    this.chatQuotaExhausted = false;
  }

  /// Background pause (combined chat focused elsewhere): stop polling to
  /// save quota. The channel buffer and its page token stay, so
  /// [resumePolling] continues where it left off. No-op when idle.
  @observable
  bool pollingPaused = false;

  @action
  void pausePolling() {
    if (this.pollingPaused) return;
    if (this.chatConnection == YouTubeChatConnectionState.idle) return;
    this.pollingPaused = true;
    this._stopPolling();
  }

  @action
  void resumePolling() {
    if (!this.pollingPaused) return;
    this.pollingPaused = false;
    this.connectChat();
  }

  void _stopPolling() {
    this._pollFlow++;
    runInAction(() {
      this.chatConnection = YouTubeChatConnectionState.idle;
      this.awaitingLiveStream = false;
      this.chatError = null;
      this._clearQuotaStop();
      this.sendChatError = null;
      this.moderationError = null;
    });
  }

  /// The read transport. One pass of [_attachAndPoll] resolves the entry's
  /// live chat and polls it until it ends or fails. Video entries stop
  /// there (terminal `offline`); channel entries wait on
  /// [kYouTubeLiveRecheckSchedule] and re-resolve, so the chat reattaches to the
  /// channel's next stream on its own. A bumped [_pollFlow] (selectChannel
  /// / logout / dispose / [recheckLiveNow]) cancels the loop.
  Future<void> _pollLoop(String label, int flow) async {
    final buffer = this._channelBuffers.putIfAbsent(label, _ChannelBuffer.new);
    final apiKey = YouTubeLiveChatService.resolveApiKey();

    bool superseded() =>
        flow != this._pollFlow || label != this.selectedChannelLabel;

    var recheck = 0;
    var retryMillis = 0;
    while (!superseded()) {
      final outcome = await this._attachAndPoll(
        label,
        buffer,
        apiKey,
        superseded,
      );
      if (superseded()) return;
      if (outcome == _PassOutcome.retry) {
        retryMillis = retryMillis == 0 ? kInitialRetryMillis : retryMillis * 2;
        if (retryMillis > kMaxBackoffMillis) retryMillis = kMaxBackoffMillis;
        await this._sleep(Duration(milliseconds: retryMillis));
        continue;
      }
      retryMillis = 0;
      if (outcome == _PassOutcome.attached) recheck = 0;
      if (outcome == _PassOutcome.stopped) return;
      if (this._selectedTarget is! YouTubeChannelTarget) {
        runInAction(() {
          this.chatConnection = YouTubeChatConnectionState.offline;
        });
        return;
      }
      runInAction(() {
        this.chatConnection = YouTubeChatConnectionState.offline;
        this.awaitingLiveStream = true;
      });
      const schedule = kYouTubeLiveRecheckSchedule;
      await this._sleep(
        schedule[recheck < schedule.length ? recheck : schedule.length - 1],
      );
      recheck++;
    }
  }

  /// Skip the remaining wait of a channel entry that's between streams
  /// (UI "Check now") — restarts the loop, which re-resolves immediately.
  @action
  void recheckLiveNow() {
    if (!this.awaitingLiveStream) return;
    this.connectChat();
  }

  /// App back in the foreground: a poll that failed or is backing off
  /// while the app was suspended restarts now instead of waiting out its
  /// timer, and a channel between streams checks at once. A paused poll
  /// (combined chat focused elsewhere) stays paused; quota exhaustion
  /// waits for the daily reset (and restarts here once it has passed - the
  /// reset timer doesn't run while iOS suspends the app).
  @action
  void reconnectAfterResume() {
    if (this.pollingPaused) return;
    if (this.chatQuotaExhausted) {
      final resetAt = this.quotaResetAt;
      if (resetAt != null && !this._now().isBefore(resetAt)) {
        this.connectChat();
      }
      return;
    }
    final retrying =
        this.chatConnection == YouTubeChatConnectionState.connecting &&
        this.chatError != null;
    if (this.chatConnection == YouTubeChatConnectionState.error ||
        retrying ||
        this.awaitingLiveStream) {
      this.connectChat();
    }
  }

  /// Resolve the selected entry's `activeLiveChatId` (cached in [buffer])
  /// and poll `liveChatMessages.list`, honoring each page's
  /// `pollingIntervalMillis` (net of the elapsed request duration) and
  /// threading the page token.
  ///
  /// Returns [_PassOutcome.offline] when nothing is live,
  /// [_PassOutcome.attached] when a chat connected and has since ended
  /// (the caller decides whether to wait for the next stream either way),
  /// and [_PassOutcome.stopped] for terminal states (quota exhausted, API /
  /// channel-not-found errors — [chatConnection] already `error` — or a
  /// superseded loop). A transient resolve failure returns
  /// [_PassOutcome.retry]; rate limiting and transient poll failures back
  /// off and retry in place, the chat showing `connecting` meanwhile.
  Future<_PassOutcome> _attachAndPoll(
    String label,
    _ChannelBuffer buffer,
    String apiKey,
    bool Function() superseded,
  ) async {
    void quotaExhausted(Object e) {
      GeneralHelper.logFailure('YouTube API quota used up', e);
      final resetAt = nextYouTubeQuotaReset(
        this._now(),
      ).add(kYouTubeQuotaResetGrace);
      runInAction(() {
        this.chatConnection = YouTubeChatConnectionState.error;
        this.awaitingLiveStream = false;
        this.chatQuotaExhausted = true;
        this.quotaResetAt = resetAt;
        this.chatError =
            'YouTube API quota used up for today - the chat restarts on its '
            'own after the daily reset (midnight Pacific time)';
      });
      this._quotaResetTimer?.cancel();
      this._quotaResetTimer = Timer(resetAt.difference(this._now()), () {
        this._quotaResetTimer = null;
        if (this.chatQuotaExhausted && !this.pollingPaused) {
          this.connectChat();
        }
      });
    }

    void failed(String message) {
      runInAction(() {
        this.chatConnection = YouTubeChatConnectionState.error;
        this.awaitingLiveStream = false;
        this.chatError = message;
      });
    }

    /// Not an error state: the loop retries on its own, the reason stays
    /// visible while it does.
    void retrying(String message) {
      runInAction(() {
        this.chatConnection = YouTubeChatConnectionState.connecting;
        this.awaitingLiveStream = false;
        this.chatError = message;
      });
    }

    if (buffer.liveChatId == null) {
      final target = this._selectedTarget;
      if (target == null) {
        /// Channel vanished from settings mid-flight — treat as no
        /// selection.
        if (!superseded()) {
          runInAction(() {
            this.chatConnection = YouTubeChatConnectionState.idle;
            this.awaitingLiveStream = false;
          });
        }
        return _PassOutcome.stopped;
      }

      switch (target) {
        case YouTubeVideoTarget(:final videoId):
          buffer.videoId = videoId;
        case YouTubeChannelTarget():
          final String? liveVideoId;
          try {
            liveVideoId = await this._liveResolver.resolveLiveVideoId(target);
          } on YouTubeLiveResolveException catch (e) {
            if (superseded()) return _PassOutcome.stopped;
            GeneralHelper.logFailure('YouTube live lookup failed', e);
            if (e.statusCode == 404) {
              failed(e.message);
              return _PassOutcome.stopped;
            }

            /// Network hiccup / consent wall / layout drift — not
            /// "offline" for sure, but retrying on the recheck schedule
            /// is still the right move. The reason stays visible.
            runInAction(() => this.chatError = e.message);
            return _PassOutcome.offline;
          }
          if (superseded()) return _PassOutcome.stopped;
          runInAction(() => this.chatError = null);
          if (liveVideoId == null || liveVideoId == buffer.endedVideoId) {
            return _PassOutcome.offline;
          }
          if (buffer.videoId != null && buffer.videoId != liveVideoId) {
            /// A new stream on the same channel: the old chat's cursor is
            /// meaningless there. Buffered rows stay as history.
            buffer.nextPageToken = null;
          }
          buffer.videoId = liveVideoId;
      }
      try {
        final resolved = await this._chatService.resolveLiveStreamingDetails(
          buffer.videoId!,
          apiKey: apiKey,
        );
        buffer.liveChatId = resolved.liveChatId;
        buffer.viewerCount = resolved.concurrentViewers;
        buffer.channelId = resolved.channelId;
      } on YouTubeQuotaExceededException catch (e) {
        if (superseded()) return _PassOutcome.stopped;
        quotaExhausted(e);
        return _PassOutcome.stopped;
      } on YouTubeRateLimitedException catch (e) {
        if (superseded()) return _PassOutcome.stopped;
        GeneralHelper.logFailure('YouTube live chat resolve throttled', e);
        retrying('YouTube is busy - retrying');
        return _PassOutcome.retry;
      } catch (e) {
        if (superseded()) return _PassOutcome.stopped;
        GeneralHelper.logFailure('YouTube live chat resolve failed', e);
        if (_isTransientReadFailure(e)) {
          retrying('Could not reach YouTube - retrying');
          return _PassOutcome.retry;
        }
        failed('Could not resolve the live chat');
        return _PassOutcome.stopped;
      }
      if (superseded()) return _PassOutcome.stopped;
      if (buffer.liveChatId == null) {
        /// Video is not live (or has chat disabled) — a normal state,
        /// not an error. Also clears any stale viewer count.
        runInAction(() {
          this.selectedChannelViewerCount = null;
          this.selectedLiveVideoId = null;
        });
        return _PassOutcome.offline;
      }
      runInAction(() {
        this.selectedChannelViewerCount = buffer.viewerCount;
        this.selectedLiveVideoId = buffer.videoId;
        final videoId = buffer.videoId;

        /// Attached: learn this chat's emojis (member ones too) - rate
        /// limited, quota-free
        if (videoId != null) unawaited(this._emojis?.learn(videoId));
      });
    }

    int lastIntervalMillis = 5000;
    int backoffMillis = 0;
    var attached = false;

    Future<void> backOff() {
      backoffMillis = backoffMillis == 0
          ? lastIntervalMillis * 2
          : backoffMillis * 2;
      if (backoffMillis > kMaxBackoffMillis) {
        backoffMillis = kMaxBackoffMillis;
      }
      return this._sleep(Duration(milliseconds: backoffMillis));
    }

    /// Viewer count refresh — resolved once per connect otherwise.
    final viewerStopwatch = Stopwatch()..start();

    /// The chat is over: remember which video so a channel's lagging
    /// `/live` page doesn't re-attach to it, and drop the dead cursor.
    _PassOutcome ended() {
      buffer.endedVideoId = buffer.videoId;
      buffer.liveChatId = null;
      buffer.nextPageToken = null;
      buffer.nextPollAt = null;
      buffer.viewerCount = null;
      runInAction(() {
        this.selectedChannelViewerCount = null;
        this.selectedLiveVideoId = null;
      });
      return attached ? _PassOutcome.attached : _PassOutcome.offline;
    }

    /// A resumed poll (switch back, un-pause, app resume) waits out the
    /// rest of the last page's interval - polling sooner answers
    /// `rateLimitExceeded`.
    final resumeAt = buffer.nextPollAt;
    if (resumeAt != null) {
      final wait = resumeAt.difference(this._now());
      if (wait > Duration.zero) {
        await this._sleep(wait);
        if (superseded()) return _PassOutcome.stopped;
      }
    }

    while (!superseded()) {
      YouTubeLiveChatPage page;
      try {
        page = await this._chatService.listMessages(
          buffer.liveChatId!,
          buffer.nextPageToken,
          apiKey: apiKey,
        );
      } on YouTubeRateLimitedException {
        if (superseded()) return _PassOutcome.stopped;
        final wait = backOff();
        GeneralHelper.advLog(
          'YouTube chat rate limited - backing off ${backoffMillis}ms',
        );
        await wait;
        continue;
      } on YouTubeQuotaExceededException catch (e) {
        if (superseded()) return _PassOutcome.stopped;
        quotaExhausted(e);
        return _PassOutcome.stopped;
      } on YouTubeChatEndedException {
        if (superseded()) return _PassOutcome.stopped;
        return ended();
      } catch (e) {
        if (superseded()) return _PassOutcome.stopped;
        GeneralHelper.logFailure('YouTube chat poll failed', e);
        if (!_isTransientReadFailure(e)) {
          failed('Lost connection to YouTube chat');
          return _PassOutcome.stopped;
        }

        /// Cursor and chat id stay — the retry picks up where the
        /// dropped request left off.
        retrying('Lost connection to YouTube chat - reconnecting');
        await backOff();
        continue;
      }
      if (superseded()) return _PassOutcome.stopped;

      backoffMillis = 0;
      lastIntervalMillis = page.pollingIntervalMillis;
      buffer.nextPollAt = this._now().add(
        Duration(milliseconds: page.pollingIntervalMillis),
      );

      /// No cursor yet = this is the chat's first page, which YouTube
      /// fills with recent history — mark it historical (dimmed + the
      /// "New messages" divider after it).
      final historyPage = buffer.nextPageToken == null;
      buffer.nextPageToken = page.nextPageToken;
      attached = true;
      runInAction(() {
        this.chatConnection = YouTubeChatConnectionState.connected;
        this.awaitingLiveStream = false;
        this.chatError = null;
        if (this.sendChatError == _kSendNoStreamText ||
            this.sendChatError == _kSendNotConnectedText) {
          this.sendChatError = null;
        }
        final poll = page.activePollItem;
        buffer.activePoll = poll;
        if (this.selectedChannelLabel == label) this.activePoll = poll;
        this._applyPageMessages(
          label,
          historyPage
              ? [for (final m in page.messages) m.copyWith(isHistorical: true)]
              : page.messages,
        );
      });

      if (page.offlineAt != null ||
          page.messages.any(
            (m) => m.type == YouTubeChatMessageType.chatEnded,
          )) {
        return ended();
      }

      if (viewerStopwatch.elapsed >= this._viewerRefreshInterval) {
        viewerStopwatch.reset();
        await this._refreshViewerCount(label, buffer, apiKey, superseded);
        if (superseded()) return _PassOutcome.stopped;
      }

      /// Google: "the amount of time the client should wait before
      /// polling again" - counted from the answer, so the full interval
      /// (less only the time spent on the viewer refresh above).
      final remaining = buffer.nextPollAt!.difference(this._now());
      await this._sleep(remaining > Duration.zero ? remaining : Duration.zero);
    }
    return _PassOutcome.stopped;
  }

  /// Re-read the live video's `concurrentViewers` (1 quota unit) so the
  /// LIVE chips follow a growing stream. Best effort: failures keep the
  /// last count.
  Future<void> _refreshViewerCount(
    String label,
    _ChannelBuffer buffer,
    String apiKey,
    bool Function() superseded,
  ) async {
    final videoId = buffer.videoId;
    if (videoId == null) return;
    try {
      final details = await this._chatService.resolveLiveStreamingDetails(
        videoId,
        apiKey: apiKey,
      );
      if (superseded() || details.concurrentViewers == null) return;
      buffer.viewerCount = details.concurrentViewers;
      runInAction(() {
        if (this.selectedChannelLabel == label) {
          this.selectedChannelViewerCount = details.concurrentViewers;
        }
      });
    } catch (e) {
      GeneralHelper.logFailure('YouTube viewer count refresh failed', e);
    }
  }

  /// Route one poll page: lifecycle events (tombstone / userBanned) mutate
  /// the buffer, everything else appends as a row (deduped by message id —
  /// a local send's [YouTubeChatMessage] is already buffered when its poll
  /// echo arrives).
  /// Live rows of the selected chat as they arrive - no first-page
  /// history, no lifecycle events (text-to-speech listens here)
  final StreamController<YouTubeChatMessage> _liveMessages =
      StreamController.broadcast();

  Stream<YouTubeChatMessage> get liveMessages => this._liveMessages.stream;

  /// Activity feed rows (super chats, stickers, memberships, gifting) of
  /// the user's OWN broadcast, history page included - the poll re-sends
  /// the backlog after a reconnect and the feed dedupes by message id.
  final StreamController<ActivityEvent> _activityEvents =
      StreamController.broadcast();

  Stream<ActivityEvent> get activityEvents => this._activityEvents.stream;

  void _emitActivity(String label, YouTubeChatMessage item) {
    final ownId = this.selfChannelId;
    if (ownId == null ||
        !this.isOwnChannel(label) ||
        this._activityEvents.isClosed) {
      return;
    }
    final activity = youTubeActivityFromMessage(item, ownId);
    if (activity != null) this._activityEvents.add(activity);
  }

  void _applyPageMessages(String label, List<YouTubeChatMessage> items) {
    for (final item in items) {
      switch (item.type) {
        case YouTubeChatMessageType.tombstone:
          this._applyTombstone(label, item);
        case YouTubeChatMessageType.userBanned:
          this._applyUserBanned(label, item);
        default:
          final known = this.messages.indexWhere(
            (message) => message.id == item.id,
          );
          if (known >= 0) {
            /// Our own sent message comes back from the poll with the
            /// real author details (badges) - it replaces the instant copy
            if (this._localEchoIds.remove(item.id)) {
              this.messages[known] = item.copyWith(
                isTombstoned: this.messages[known].isTombstoned,
                isHistorical: this.messages[known].isHistorical,
              );
            }
            continue;
          }
          this.messages.add(item);
          while (this.messages.length > this.messageCap.value) {
            this.messages.removeAt(0);
          }
          this._emitActivity(label, item);
          this._emojis?.noteText(
            item.copyText,
            videoId: this._channelBuffers[label]?.videoId,
            channelId: this._channelBuffers[label]?.channelId,
          );
          if (!item.isHistorical &&
              this.selectedChannelLabel == label &&
              !this._liveMessages.isClosed) {
            this._liveMessages.add(item);
          }
      }
    }
  }

  /// A `tombstone` carries the id of the deleted message — mark the
  /// buffered copy (dim + marker, same UX as Twitch); unknown ids are
  /// dropped. Echoes of local deletes are skipped via the applied-keys
  /// dedup.
  @action
  void _applyTombstone(String label, YouTubeChatMessage tombstone) {
    if (!this._moderationKeyIsNew('$label:delete:${tombstone.id}')) return;
    final index = this.messages.indexWhere(
      (message) => message.id == tombstone.id,
    );
    if (index < 0) return;
    this.messages[index] = this.messages[index].copyWith(isTombstoned: true);
  }

  /// `userBannedEvent` — tombstone every buffered message of the banned
  /// author (Twitch precedent: purge = tombstone, not removal). The event
  /// itself is not appended as a row.
  @action
  void _applyUserBanned(String label, YouTubeChatMessage event) {
    final details = event.snippet.userBannedDetails;
    final bannedChannelId = details?.bannedUserDetails?.channelId;
    if (bannedChannelId == null || bannedChannelId.isEmpty) return;
    if (!this._moderationKeyIsNew('$label:purge:$bannedChannelId')) return;
    final seconds = details?.banDurationSeconds;
    this._recordBan(
      ChatBanEntry(
        userId: bannedChannelId,
        userName: details?.bannedUserDetails?.displayName,
        expiresAt: details?.banType == 'temporary' && seconds != null
            ? event.publishedAt.add(Duration(seconds: seconds))
            : null,
        bannedBy: event.authorName,
        at: event.publishedAt,
      ),
    );
    for (var i = 0; i < this.messages.length; i++) {
      final message = this.messages[i];
      if (message.snippet.authorChannelId == bannedChannelId &&
          !message.isTombstoned) {
        this.messages[i] = message.copyWith(isTombstoned: true);
      }
    }
  }

  /// Whether [key] was already applied — first-time keys are recorded
  /// (bounded FIFO) and reported as new. See [_appliedModerationKeys].
  bool _moderationKeyIsNew(String key) {
    if (!this._appliedModerationKeys.add(key)) return false;
    this._appliedModerationOrder.addLast(key);
    while (this._appliedModerationOrder.length > _kMaxAppliedModerationKeys) {
      this._appliedModerationKeys.remove(
        this._appliedModerationOrder.removeFirst(),
      );
    }
    return true;
  }

  /// Multi-chat: switch the visible channel (null = no selection / stop).
  /// Only the visible channel is polled — the old channel's chat snapshot
  /// is buffered in memory and restored on switch-back; the poll resumes
  /// from the buffered page token.
  @action
  Future<void> selectChannel(String? label) async {
    if (label == this.selectedChannelLabel) return;

    // Cancel the running loop BEFORE touching state so its continuations
    // cannot write into the new channel's buffer.
    this._pollFlow++;

    final previousLabel = this.selectedChannelLabel;
    if (previousLabel != null) {
      final previous = this._channelBuffers.putIfAbsent(
        previousLabel,
        _ChannelBuffer.new,
      );
      previous.messages = List.of(this.messages);
      previous.bans = List.of(this.recentBans);
      previous.activePoll = this.activePoll;
    }

    this.selectedChannelLabel = label;
    this._persistSelectedChannel();
    this.sendChatError = null;
    this.moderationError = null;
    this.moderationForbidden = false;
    this.recentBans.clear();
    this.activePoll = null;
    this.moderators = null;

    this.messages.clear();
    if (label != null) {
      final buffer = this._channelBuffers.putIfAbsent(
        label,
        _ChannelBuffer.new,
      );
      this.messages.addAll(buffer.messages);
      this.recentBans.addAll(buffer.bans);
      this.activePoll = buffer.activePoll;
      this.selectedChannelViewerCount = buffer.viewerCount;
      this.selectedLiveVideoId = buffer.liveChatId != null
          ? buffer.videoId
          : null;
      this.awaitingLiveStream = false;
      if (this._isProResolver()) {
        this.chatConnection = YouTubeChatConnectionState.connecting;
        this.chatError = null;
        this._clearQuotaStop();
        final flow = this._pollFlow;
        unawaited(this._pollLoop(label, flow));
      } else {
        /// Hard entitlement gate (mirrors [connectChat]): the selection
        /// is kept, but without Pro no poll loop starts
        this.chatConnection = YouTubeChatConnectionState.idle;
      }
    } else {
      this.selectedChannelViewerCount = null;
      this.selectedLiveVideoId = null;
      this.awaitingLiveStream = false;
      this.chatConnection = YouTubeChatConnectionState.idle;
    }
  }

  /// After an add dialog: re-read the list and show the entry it added.
  /// Nothing added (cancelled): the selection stays.
  @action
  void showAddedChannel(List<String> before) {
    this.reloadChannels();
    final added = [
      for (final channel in this.channels)
        if (!before.contains(channel.label)) channel.label,
    ];
    if (added.isEmpty) return;
    unawaited(this.selectChannel(added.first));
  }

  /// "Add chat" picker: list [target] under [name] (made unique; an
  /// entry already pointing at it keeps its label) and switch to it.
  /// Native only: the WebView selection stays as it was. Returns the
  /// label, null when saving failed.
  /// [aliasKeys]: the channel's other stored form (see
  /// [youTubeEntryLabelFor]) - an `@handle` pick finds a `UC…` entry and
  /// the own channel.
  @action
  Future<String?> addChannelEntry(
    YouTubeTarget target,
    String name, {
    Iterable<String> aliasKeys = const [],
  }) async {
    final own = this.ownChannel;
    if (own != null && {target.key, ...aliasKeys}.contains(own.target.key)) {
      await this.selectChannel(kYouTubeOwnChannelLabel);
      return kYouTubeOwnChannelLabel;
    }
    final String label;
    try {
      final box = Hive.box(HiveKeys.Settings.name);
      final entries = Map<String, String>.from(
        box.get(
          SettingsKeys.YouTubeUsernames.name,
          defaultValue: <String, String>{},
        ),
      );
      final pick = youTubeEntryLabelFor(
        target,
        name,
        entries,
        aliasKeys: aliasKeys,
      );
      label = pick.label;
      if (!pick.existing) {
        entries[label] = target.storageValue;
        box.put(SettingsKeys.YouTubeUsernames.name, entries);
      }
    } catch (e) {
      GeneralHelper.logFailure('YouTube channel add failed', e);
      return null;
    }
    this.reloadChannels();
    await this.selectChannel(label);
    return label;
  }

  /// The picker's "Channels you subscribe to" — signed-in accounts with a
  /// channel only (a channel-less account subscribes to nothing). Logged
  /// and rethrown for the picker's retry row.
  Future<List<YouTubeChannelSuggestion>> loadSubscriptions(
    YouTubeChannelSearchService service,
  ) async {
    if (!this.isSignedIn || this.signedInWithoutChannel) return const [];
    try {
      return await service.listSubscriptions(
        accessToken: await this._validAccessToken(),
      );
    } catch (e) {
      GeneralHelper.logFailure('YouTube subscriptions load failed', e);

      /// A dead session signs out (same rule as writes) - the picker then
      /// shows its signed-out state instead of a Retry that can't work.
      if (e is YouTubeApiException) await this._expireRejectedToken(e);
      if (await this._endSessionIfDead(e)) return const [];
      rethrow;
    }
  }

  /// Re-read the channel list from settings (after the user edited
  /// [SettingsKeys.YouTubeUsernames] outside this store). A label whose
  /// target (video or channel) changed is a new conversation: retire its
  /// cursor, liveChatId and messages. A vanished selection falls back to
  /// none.
  @action
  void reloadChannels() {
    final parsed = this._readChannelsFromSettings();
    final videos = {
      for (final channel in parsed) channel.label: channel.target.key,
    };
    final retired = {
      for (final channel in this.channels)
        if (videos[channel.label] != channel.target.key) channel.label,
    };
    final selected = this.selectedChannelLabel;
    final retireSelection =
        selected != null &&
        selected != kYouTubeOwnChannelLabel &&
        (retired.contains(selected) || !videos.containsKey(selected));
    if (retireSelection) {
      // Invalidate in-flight reads before clearing their visible destination.
      // Do not call selectChannel: it would save the retired messages again.
      this._stopPolling();
      this.messages.clear();
    }
    this.channels
      ..clear()
      ..addAll(parsed);
    this._channelBuffers.removeWhere(
      (label, _) =>
          label != kYouTubeOwnChannelLabel &&
          (retired.contains(label) || !videos.containsKey(label)),
    );
    bool retiredModeration(String key) =>
        retired.any((label) => key.startsWith('$label:'));
    this._appliedModerationKeys.removeWhere(retiredModeration);
    this._appliedModerationOrder.removeWhere(retiredModeration);
    if (retireSelection) {
      if (!videos.containsKey(selected)) {
        this.selectedChannelLabel = null;
        this._persistSelectedChannel();
      } else if (this.canRead) {
        this._restartPolling();
      }
    }
  }

  /// Idempotent settings load (init + fresh sign-in): restores [channels]
  /// and [selectedChannelLabel]. Missing keys degrade to empty/null;
  /// garbage/unparseable entries are skipped one by one. A persisted
  /// selection that no longer matches a stored channel falls back to none.
  void _ensureChannelsLoaded() {
    if (this._channelsLoaded) return;
    this._channelsLoaded = true;
    this.channels.addAll(this._readChannelsFromSettings());
    try {
      final selected = Hive.box(
        HiveKeys.Settings.name,
      ).get(SettingsKeys.SelectedYouTubeNativeChannelId.name);

      /// The own entry isn't known until the session restores —
      /// [_syncOwnChannel] drops the selection if it never appears.
      if (selected is String &&
          (selected == kYouTubeOwnChannelLabel ||
              this.channels.any((channel) => channel.label == selected))) {
        this.selectedChannelLabel = selected;
      }
    } catch (e) {
      GeneralHelper.logFailure('YouTube chat selection load failed', e);
    }
  }

  List<YouTubeChatChannel> _readChannelsFromSettings() {
    final parsed = <YouTubeChatChannel>[];
    try {
      final raw = Hive.box(HiveKeys.Settings.name).get(
        SettingsKeys.YouTubeUsernames.name,
        defaultValue: <String, String>{},
      );
      if (raw is Map) {
        raw.forEach((key, value) {
          if (key is String && value is String) {
            final target = parseYouTubeTarget(value);
            if (target != null) {
              parsed.add(YouTubeChatChannel(label: key, target: target));
            }
          }
        });
      }
    } catch (e) {
      GeneralHelper.logFailure('YouTube chat channels load failed', e);
    }
    return parsed;
  }

  void _persistSelectedChannel() {
    try {
      final box = Hive.box(HiveKeys.Settings.name);
      if (this.selectedChannelLabel == null) {
        box.delete(SettingsKeys.SelectedYouTubeNativeChannelId.name);
      } else {
        box.put(
          SettingsKeys.SelectedYouTubeNativeChannelId.name,
          this.selectedChannelLabel,
        );
      }
    } catch (e) {
      GeneralHelper.logFailure('YouTube chat selection persist failed', e);
    }
  }

  /// Send a chat message as the signed-in user into the selected channel's
  /// live chat. Returns whether it was delivered — never throws; failures
  /// surface in [sendChatError]. The sent message is appended optimistically;
  /// its poll echo lands as a no-op (id dedup in [_applyPageMessages]).
  @action
  Future<bool> sendChatMessage(String text) async {
    final trimmed = text.trim();
    if (!this.canWrite || trimmed.isEmpty || this.sendingChat) {
      return false;
    }
    if (trimmed.length > kYouTubeChatMessageMaxLength) {
      this.sendChatError =
          'YouTube messages can be up to $kYouTubeChatMessageMaxLength '
          'characters';
      return false;
    }
    final label = this.selectedChannelLabel;
    final buffer = this._channelBuffers[label];
    final liveChatId = buffer?.liveChatId;
    final targetKey = this._selectedTarget?.key;

    /// Only a chat we are attached to takes messages — say why instead of
    /// a send that silently does nothing.
    if (this.chatConnection != YouTubeChatConnectionState.connected ||
        label == null ||
        buffer == null ||
        liveChatId == null ||
        targetKey == null) {
      this.sendChatError = this.awaitingLiveStream
          ? _kSendNoStreamText
          : _kSendNotConnectedText;
      return false;
    }
    final loginFlow = this._loginFlow;
    bool ownsDestination() =>
        loginFlow == this._loginFlow &&
        identical(buffer, this._channelBuffers[label]) &&
        this.nativeChannels.any(
          (channel) =>
              channel.label == label && channel.target.key == targetKey,
        );
    bool sameChannel() =>
        ownsDestination() && this.selectedChannelLabel == label;
    this.sendingChat = true;
    this.sendChatError = null;

    try {
      final token = await this._validAccessToken();
      if (!ownsDestination()) return false;
      final inserted = await this._chatService.insert(
        accessToken: token,
        liveChatId: liveChatId,
        message: trimmed,
      );

      /// `liveChatMessages.insert` answers with the snippet only - no
      /// authorDetails, so the instant copy would read "Unknown". Fill in
      /// who we are; the poll's copy (real badges) replaces it later.
      final sent = inserted.authorDetails != null
          ? inserted
          : inserted.copyWith(
              authorDetails: YouTubeChatAuthorDetails(
                channelId: inserted.authorChannelId ?? this.selfChannelId,
                displayName: this.selfChannelTitle ?? 'You',

                /// The chat it went to, not whatever is selected by now
                isChatOwner: this.isOwnChannel(label),
              ),
            );
      this._localEchoIds.add(sent.id);
      if (ownsDestination()) {
        final destination = sameChannel() ? this.messages : buffer.messages;
        if (!destination.any((message) => message.id == sent.id)) {
          destination.add(sent);
          final cap = identical(destination, this.messages)
              ? this.messageCap.value
              : kMaxMessages;
          while (destination.length > cap) {
            destination.removeAt(0);
          }
        }
      }
      return true;
    } on YouTubeApiException catch (e) {
      GeneralHelper.logFailure('YouTube chat send failed', e);
      await this._expireRejectedToken(e);
      if (sameChannel()) {
        this.sendChatError = e.statusCode == 401
            ? 'Could not send - try again'
            : e.message;
      }
      return false;
    } catch (e) {
      GeneralHelper.logFailure('YouTube chat send failed', e);
      if (await this._endSessionIfDead(e)) return false;
      if (sameChannel()) {
        this.sendChatError = 'Could not send - try again';
      }
      return false;
    } finally {
      this.sendingChat = false;
    }
  }

  /// Delete [messageId] in the selected channel's live chat (owner/mod
  /// only — a 403 surfaces via [moderationError], plan §7). Returns
  /// whether the server accepted the delete — never throws. On success
  /// the tombstone applies locally when the id is buffered (a stale or
  /// already-evicted id is still a successful delete) and the poll echo
  /// is pre-marked so it lands as a no-op.
  @action
  Future<bool> deleteMessage(String messageId) async {
    if (!this.canWrite) return false;
    this.moderationError = null;
    this.moderationForbidden = false;
    try {
      final token = await this._validAccessToken();
      await this._chatService.delete(accessToken: token, messageId: messageId);
    } on YouTubeApiException catch (e) {
      GeneralHelper.logFailure('YouTube message delete failed', e);
      await this._expireRejectedToken(e);
      this.moderationError = e.message;
      this.moderationForbidden = _isNotModerator(e);
      return false;
    } catch (e) {
      GeneralHelper.logFailure('YouTube message delete failed', e);
      if (await this._endSessionIfDead(e)) return false;
      this.moderationError = 'Could not delete the message';
      return false;
    }
    final label = this.selectedChannelLabel ?? '';
    this._moderationKeyIsNew('$label:delete:$messageId');
    final index = this.messages.indexWhere(
      (message) => message.id == messageId,
    );
    if (index >= 0) {
      this.messages[index] = this.messages[index].copyWith(isTombstoned: true);
    }
    return true;
  }

  /// Ban [channelId] in the selected channel's live chat — permanently, or
  /// as a timeout when [durationSeconds] is set. Same return/echo contract
  /// as [deleteMessage]: the local purge marks the `userBannedEvent` echo
  /// key first.
  @action
  Future<bool> banUser(String channelId, {int? durationSeconds}) async {
    if (!this.canWrite) return false;
    final label = this.selectedChannelLabel;
    final liveChatId = this._channelBuffers[label]?.liveChatId;
    if (label == null || liveChatId == null) return false;
    this.moderationError = null;
    this.moderationForbidden = false;
    final String? banId;
    try {
      final token = await this._validAccessToken();
      banId = await this._chatService.ban(
        accessToken: token,
        liveChatId: liveChatId,
        channelId: channelId,
        durationSeconds: durationSeconds,
      );
    } on YouTubeApiException catch (e) {
      GeneralHelper.logFailure('YouTube ban failed', e);
      await this._expireRejectedToken(e);
      this.moderationError = e.message;
      this.moderationForbidden = _isNotModerator(e);
      return false;
    } catch (e) {
      GeneralHelper.logFailure('YouTube ban failed', e);
      if (await this._endSessionIfDead(e)) return false;
      this.moderationError = 'Could not ban the user';
      return false;
    }
    this._moderationKeyIsNew('$label:purge:$channelId');
    String? name;
    for (final message in this.messages) {
      if (message.snippet.authorChannelId == channelId) {
        name = message.authorName;
      }
    }
    this._recordBan(
      ChatBanEntry(
        userId: channelId,
        userName: name,
        expiresAt: durationSeconds == null
            ? null
            : DateTime.now().add(Duration(seconds: durationSeconds)),
        bannedBy: this.selfChannelTitle,
        banId: banId,
        at: DateTime.now(),
      ),
    );
    for (var i = 0; i < this.messages.length; i++) {
      final message = this.messages[i];
      if (message.snippet.authorChannelId == channelId &&
          !message.isTombstoned) {
        this.messages[i] = message.copyWith(isTombstoned: true);
      }
    }
    return true;
  }

  /// Lift a ban — [banId] is the id of the ban resource (not the channel
  /// id). No local reconcile: unbans don't resurrect tombstoned rows.
  @action
  Future<bool> unbanUser(String banId) async {
    if (!this.canWrite) return false;
    this.moderationError = null;
    this.moderationForbidden = false;
    try {
      final token = await this._validAccessToken();
      await this._chatService.unban(accessToken: token, banId: banId);
      this.recentBans.removeWhere((ban) => ban.banId == banId);
      this._syncModerationToBuffer();
    } on YouTubeApiException catch (e) {
      GeneralHelper.logFailure('YouTube unban failed', e);
      await this._expireRejectedToken(e);
      this.moderationError = e.message;
      this.moderationForbidden = _isNotModerator(e);
      return false;
    } catch (e) {
      GeneralHelper.logFailure('YouTube unban failed', e);
      if (await this._endSessionIfDead(e)) return false;
      this.moderationError = 'Could not lift the ban';
      return false;
    }
    return true;
  }

  /// Newest first; one entry per user. A later echo keeps the ban id an
  /// own action stored first.
  void _recordBan(ChatBanEntry entry) {
    final index = this.recentBans.indexWhere((b) => b.userId == entry.userId);
    final kept = index >= 0 ? this.recentBans.removeAt(index) : null;
    this.recentBans.insert(
      0,
      entry.copyWith(
        userName: entry.userName ?? kept?.userName,
        banId: entry.banId ?? kept?.banId,
      ),
    );
    this._syncModerationToBuffer();
  }

  void _syncModerationToBuffer() {
    final label = this.selectedChannelLabel;
    if (label == null) return;
    this._channelBuffers.putIfAbsent(label, _ChannelBuffer.new).bans = List.of(
      this.recentBans,
    );
  }

  /// Run a channel mod call ([moderationError] / [moderationForbidden]
  /// on failure) against the selected chat's `liveChatId`.
  Future<bool> _channelModAction(
    String failure,
    Future<void> Function(String token, String liveChatId) call,
  ) async {
    if (!this.canWrite) return false;
    final liveChatId =
        this._channelBuffers[this.selectedChannelLabel]?.liveChatId;
    this.moderationError = null;
    this.moderationForbidden = false;
    if (liveChatId == null) {
      this.moderationError = '$failure - the chat is not live';
      return false;
    }
    try {
      await call(await this._validAccessToken(), liveChatId);
      return true;
    } on YouTubeApiException catch (e) {
      GeneralHelper.logFailure('YouTube channel mod action failed', e);
      await this._expireRejectedToken(e);
      runInAction(() {
        this.moderationError = e.message;
        this.moderationForbidden = _isNotModerator(e);
      });
      return false;
    } catch (e) {
      GeneralHelper.logFailure('YouTube channel mod action failed', e);
      if (await this._endSessionIfDead(e)) return false;
      runInAction(() => this.moderationError = failure);
      return false;
    }
  }

  /// Start a poll in the selected chat (2–4 options).
  @action
  Future<bool> createPoll(String question, List<String> options) => this
      ._channelModAction('Could not start the poll', (token, liveChatId) async {
        final poll = await this._chatService.createPoll(
          accessToken: token,
          liveChatId: liveChatId,
          question: question,
          options: options,
        );
        runInAction(() => this.activePoll = poll);
      });

  /// End the active poll.
  @action
  Future<bool> closeActivePoll() {
    final poll = this.activePoll;
    if (poll == null) return Future.value(false);
    return this._channelModAction('Could not end the poll', (token, _) async {
      await this._chatService.closePoll(
        accessToken: token,
        pollMessageId: poll.id,
      );
      runInAction(() => this.activePoll = null);
    });
  }

  /// Load the selected chat's moderators (owner-only — a 403 elsewhere
  /// sets [moderationForbidden]).
  @action
  Future<bool> loadModerators() => this._channelModAction(
    'Could not load moderators',
    (token, liveChatId) async {
      final list = await this._chatService.listModerators(
        accessToken: token,
        liveChatId: liveChatId,
      );
      runInAction(() => this.moderators = ObservableList.of(list));
    },
  );

  /// Make the author of [channelId] a moderator of the selected chat.
  @action
  Future<bool> addModerator(String channelId) => this._channelModAction(
    'Could not add the moderator',
    (token, liveChatId) async {
      final moderator = await this._chatService.addModerator(
        accessToken: token,
        liveChatId: liveChatId,
        channelId: channelId,
      );
      if (moderator != null) {
        runInAction(() => this.moderators?.add(moderator));
      }
    },
  );

  @action
  Future<bool> removeModerator(YouTubeChatModerator moderator) => this
      ._channelModAction('Could not remove the moderator', (token, _) async {
        await this._chatService.removeModerator(
          accessToken: token,
          moderatorId: moderator.id,
        );
        runInAction(
          () => this.moderators?.removeWhere((m) => m.id == moderator.id),
        );
      });

  /// A fresh access token for a one-off read (the Add chat sheet's
  /// `videos.list` without an API key); null when signed out or it fails.
  Future<String?> accessTokenForRead() async {
    if (!this.isSignedIn) return null;
    try {
      return await this._validAccessToken();
    } catch (e) {
      GeneralHelper.logFailure('YouTube access token refresh failed', e);
      return null;
    }
  }

  Future<String> _validAccessToken() async {
    final auth = this._authBox.get(YouTubeAuth.kBoxKey);
    if (auth == null) throw const YouTubeAuthException('Not signed in');

    if (auth.expiresWithin(kRefreshWindow)) {
      final token = await this._authService.refreshToken(auth.refreshToken);
      auth
        ..accessToken = token.accessToken
        ..refreshToken = token.refreshToken ?? auth.refreshToken
        ..expiresAtMs =
            DateTime.now().millisecondsSinceEpoch + token.expiresIn * 1000;
      if (token.scope.isNotEmpty) auth.scopes = token.scope;
      await auth.save();
    }
    return auth.accessToken;
  }

  Future<void> _persistAuth(
    YouTubeToken token,
    YouTubeOwnChannel? ownChannel,
  ) async {
    await this._authBox.put(
      YouTubeAuth.kBoxKey,
      YouTubeAuth(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken ?? '',
        expiresAtMs:
            DateTime.now().millisecondsSinceEpoch + token.expiresIn * 1000,
        scopes: token.scope,
        channelTitle: ownChannel?.title,
        channelId: ownChannel?.id,
      ),
    );
  }

  /// A write whose token refresh failed definitively (400 `invalid_grant`
  /// / 401 / 403 - e.g. a "Testing" OAuth app's refresh token after 7
  /// days, or access revoked in the Google account) ends the session, so
  /// the UI offers a real sign-in instead of an input that never sends.
  /// Returns whether it did.
  Future<bool> _endSessionIfDead(Object e) async {
    if (e is! YouTubeAuthException) return false;
    final status = e.statusCode;
    if (status != 400 && status != 401 && status != 403) return false;
    await this._handleInvalidAuth(
      'YouTube session expired - please sign in again',
    );
    return true;
  }

  /// A Data API 401 on a write: the access token was rejected before our
  /// clock expired it (revoked, clock skew) - expire it locally so the
  /// next write refreshes, which ends the session if the grant is dead.
  Future<void> _expireRejectedToken(YouTubeApiException e) async {
    if (e.statusCode != 401) return;
    final auth = this._authBox.get(YouTubeAuth.kBoxKey);
    if (auth == null) return;

    /// Nothing to refresh with: the session is over
    if (auth.refreshToken.isEmpty) {
      await this._handleInvalidAuth(
        'YouTube session expired - please sign in again',
      );
      return;
    }
    auth.expiresAtMs = 0;
    await auth.save();
  }

  Future<void> _handleInvalidAuth(String message) async {
    this._stopPolling();
    await this._authBox.delete(YouTubeAuth.kBoxKey);
    runInAction(() {
      this.messages.clear();
      this._channelBuffers.clear();
      this._appliedModerationKeys.clear();
      this._appliedModerationOrder.clear();
      this.authState = YouTubeAuthState.signedOut;
      this.authError = message;
      this._setNoChannel(false);
    });
    final wasOwn = this.selectedChannelLabel == kYouTubeOwnChannelLabel;
    this._syncOwnChannel();
    this._resumeReadingSignedOut(wasOwn: wasOwn);
  }

  void _resetToSignedOut() {
    this._stopPolling();
    runInAction(() {
      this.messages.clear();
      this._channelBuffers.clear();
      this._appliedModerationKeys.clear();
      this._appliedModerationOrder.clear();
      this.authState = this.isConfigured
          ? YouTubeAuthState.signedOut
          : YouTubeAuthState.unconfigured;
    });
    final wasOwn = this.selectedChannelLabel == kYouTubeOwnChannelLabel;
    this._syncOwnChannel();
    this._resumeReadingSignedOut(wasOwn: wasOwn);
  }

  /// A session end stops the poll, but reading needs only the API key:
  /// an added channel starts reading again right away. [wasOwn] = the
  /// own entry was showing — [_syncOwnChannel]'s fallback switch already
  /// started the next channel's poll.
  void _resumeReadingSignedOut({required bool wasOwn}) {
    if (!wasOwn && !this.pollingPaused) this.connectChat();
  }

  Future<void> dispose() async {
    this._pollFlow++;
    this._loginFlow++;
    this._quotaResetTimer?.cancel();
    this._quotaResetTimer = null;
    await this._authBoxSub?.cancel();
    await this._liveMessages.close();
    await this._activityEvents.close();
  }
}
