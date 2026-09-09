import 'dart:async';
import 'dart:collection';

import 'package:hive_ce/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/models/youtube_auth.dart';
import 'package:obs_blade/stores/pro_store.dart';
import 'package:obs_blade/types/classes/youtube/youtube_chat_message.dart';
import 'package:obs_blade/types/classes/youtube/youtube_token.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/general_helper.dart';
import 'package:obs_blade/utils/youtube/youtube_auth_service.dart';
import 'package:obs_blade/utils/youtube/youtube_live_chat_service.dart';
import 'package:obs_blade/utils/youtube_video_id.dart';

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

class YouTubeChatStore = _YouTubeChatStore with _$YouTubeChatStore;

/// One entry of the native YouTube channel list — derived from the
/// [SettingsKeys.YouTubeUsernames] map (label → raw value; [videoId] is
/// parsed out of the raw value via [extractYouTubeVideoId]).
class YouTubeChatChannel {
  final String label;
  final String videoId;

  const YouTubeChatChannel({required this.label, required this.videoId});
}

/// In-memory per-channel chat snapshot — swapped in/out of the live
/// [messages] list on selectChannel so switching back restores recent
/// history and the poll resumes from [nextPageToken] without re-resolving
/// [liveChatId]. Dies with the app session; never persisted (chat content
/// never touches Hive).
class _ChannelBuffer {
  List<YouTubeChatMessage> messages;
  String? liveChatId;
  String? nextPageToken;

  _ChannelBuffer({
    List<YouTubeChatMessage>? messages,
    this.liveChatId,
    this.nextPageToken,
  }) : messages = messages ?? <YouTubeChatMessage>[];
}

/// Owns the native YouTube chat: API-key gated reads, device-flow sign-in
/// state, the persisted [YouTubeAuth] record and the
/// `liveChatMessages.list` poll loop with per-channel buffers.
abstract class _YouTubeChatStore with Store {
  static const int kMaxMessages = 500;
  static const Duration kRefreshWindow = Duration(minutes: 5);

  /// Rate-limit backoff ceiling — [YouTubeRateLimitedException] doubles
  /// the wait per hit, capped here.
  static const int kMaxBackoffMillis = 60000;

  final YouTubeAuthService _authService;
  final YouTubeLiveChatService _chatService;

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

  _YouTubeChatStore({
    YouTubeAuthService? authService,
    YouTubeLiveChatService? chatService,
    Future<void> Function(Duration)? sleep,
    bool Function()? isProResolver,
  }) : _authService = authService ?? YouTubeAuthService(),
       _chatService = chatService ?? YouTubeLiveChatService(),
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

  @observable
  String? chatError;

  /// True after a [YouTubeQuotaExceededException] stopped the poll loop —
  /// polling resumes on the midnight-PT quota reset or a manual retry.
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

  /// Native YouTube channels derived from [SettingsKeys.YouTubeUsernames]
  /// (label → raw value; entries whose value doesn't parse to a video id
  /// via [extractYouTubeVideoId] are skipped).
  final ObservableList<YouTubeChatChannel> channels =
      ObservableList<YouTubeChatChannel>();

  /// Currently viewed channel — the **label** (map key of
  /// [SettingsKeys.YouTubeUsernames], stable across re-edits), persisted
  /// as [SettingsKeys.SelectedYouTubeNativeChannelId]. Null = no selection.
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

  @computed
  bool get isSignedInState => this.authState == YouTubeAuthState.signedIn;

  /// Whether the persisted token is usable for writes: present, not
  /// expired and carrying the YouTube scope. Deliberately a plain getter
  /// (not reactive): the token changes only at sign-in/sign-out, which
  /// flips [authState] and rebuilds observers.
  bool get isSignedIn {
    final auth = this._authBox.get(YouTubeAuth.kBoxKey);
    return auth != null &&
        !auth.isExpired &&
        kYouTubeChatScopes.every(auth.scopes.contains);
  }

  /// Writes (send / delete / ban) require a signed-in, scoped token.
  bool get canWrite => this.isSignedIn;

  /// Title of the signed-in channel (display only).
  String? get selfChannelTitle =>
      this._authBox.get(YouTubeAuth.kBoxKey)?.channelTitle;

  /// Video id of the selected channel, if it still exists in settings.
  String? get _selectedVideoId {
    final label = this.selectedChannelLabel;
    if (label == null) return null;
    for (final channel in this.channels) {
      if (channel.label == label) return channel.videoId;
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
      this._autoSelectChannel();
      return;
    }

    try {
      await this._validAccessToken();
    } on YouTubeAuthException catch (e) {
      /// Wipe the stored session only on a definitive auth failure — a
      /// 400 (`invalid_grant`) / 401 / 403 on refresh means the refresh
      /// token is dead; a null status is our own pre-flight throw.
      /// Anything else (transient 5xx, offline) keeps the record.
      if (e.statusCode == null ||
          e.statusCode == 400 ||
          e.statusCode == 401 ||
          e.statusCode == 403) {
        await this._handleInvalidAuth(
          'YouTube session expired — please sign in again',
        );
      } else {
        GeneralHelper.advLog('YouTube token refresh on init failed — $e');
        this.authState = YouTubeAuthState.signedOut;
      }
      return;
    }
    this.authState = YouTubeAuthState.signedIn;
    this._autoSelectChannel();
  }

  /// Select the persisted channel (or the first configured one) and start
  /// polling — no-op without a readable configuration.
  void _autoSelectChannel() {
    if (this.selectedChannelLabel == null && this.channels.isNotEmpty) {
      unawaited(this.selectChannel(this.channels.first.label));
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

      /// Channel title is display-only — a fetch failure must not fail
      /// the sign-in.
      String? channelTitle;
      try {
        channelTitle = await this._authService.fetchOwnChannelTitle(
          token.accessToken,
        );
      } catch (e) {
        GeneralHelper.advLog('YouTube channel title fetch failed — $e');
      }
      await this._persistAuth(token, channelTitle);
      this.pendingUserCode = null;
      this.pendingVerificationUrl = null;
      this.authState = YouTubeAuthState.signedIn;
      this._ensureChannelsLoaded();
      this.connectChat();
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
      GeneralHelper.advLog('YouTube login failed unexpectedly — $e');
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
    this._stopPolling();
    this.messages.clear();
    this._channelBuffers.clear();
    this._appliedModerationKeys.clear();
    this._appliedModerationOrder.clear();
    this.authState = this.isConfigured
        ? YouTubeAuthState.signedOut
        : YouTubeAuthState.unconfigured;
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
    this.chatError = null;
    this.chatQuotaExhausted = false;
    unawaited(this._pollLoop(label, flow));
  }

  void _stopPolling() {
    this._pollFlow++;
    runInAction(() {
      this.chatConnection = YouTubeChatConnectionState.idle;
      this.chatError = null;
      this.chatQuotaExhausted = false;
      this.sendChatError = null;
      this.moderationError = null;
    });
  }

  /// The read transport: resolve the selected video's `activeLiveChatId`
  /// (cached in the channel buffer), then poll `liveChatMessages.list`,
  /// honoring each page's `pollingIntervalMillis` (net of the elapsed
  /// request duration) and threading the page token. Ends on: chat ended/offlineAt (→ offline, no error), project
  /// quota exhaustion (→ error + [chatQuotaExhausted]), other API errors
  /// (→ error); transient rate limiting backs off and retries. A bumped
  /// [_pollFlow] (selectChannel / logout / dispose) cancels the loop.
  Future<void> _pollLoop(String label, int flow) async {
    final buffer = this._channelBuffers.putIfAbsent(label, _ChannelBuffer.new);
    final apiKey = YouTubeLiveChatService.resolveApiKey();

    bool superseded() =>
        flow != this._pollFlow || label != this.selectedChannelLabel;

    if (buffer.liveChatId == null) {
      final videoId = this._selectedVideoId;
      if (videoId == null) {
        /// Channel vanished from settings mid-flight — treat as no
        /// selection.
        if (!superseded()) {
          runInAction(() {
            this.chatConnection = YouTubeChatConnectionState.idle;
          });
        }
        return;
      }
      try {
        buffer.liveChatId = await this._chatService.getActiveLiveChatId(
          videoId,
          apiKey: apiKey,
        );
      } on YouTubeQuotaExceededException {
        if (superseded()) return;
        runInAction(() {
          this.chatConnection = YouTubeChatConnectionState.error;
          this.chatQuotaExhausted = true;
          this.chatError =
              'YouTube API quota exhausted — chat resumes after the daily reset';
        });
        return;
      } catch (e) {
        if (superseded()) return;
        GeneralHelper.advLog('YouTube live chat resolve failed — $e');
        runInAction(() {
          this.chatConnection = YouTubeChatConnectionState.error;
          this.chatError = 'Could not resolve the live chat';
        });
        return;
      }
      if (superseded()) return;
      if (buffer.liveChatId == null) {
        /// Video is not live (or has chat disabled) — a normal state,
        /// not an error.
        runInAction(() {
          this.chatConnection = YouTubeChatConnectionState.offline;
        });
        return;
      }
    }

    int lastIntervalMillis = 5000;
    int backoffMillis = 0;
    final callStopwatch = Stopwatch();
    while (!superseded()) {
      YouTubeLiveChatPage page;
      callStopwatch.reset();
      callStopwatch.start();
      try {
        page = await this._chatService.listMessages(
          buffer.liveChatId!,
          buffer.nextPageToken,
          apiKey: apiKey,
        );
      } on YouTubeRateLimitedException {
        if (superseded()) return;
        backoffMillis = backoffMillis == 0
            ? lastIntervalMillis * 2
            : backoffMillis * 2;
        if (backoffMillis > kMaxBackoffMillis) {
          backoffMillis = kMaxBackoffMillis;
        }
        GeneralHelper.advLog(
          'YouTube chat rate limited — backing off ${backoffMillis}ms',
        );
        await this._sleep(Duration(milliseconds: backoffMillis));
        continue;
      } on YouTubeQuotaExceededException {
        if (superseded()) return;
        runInAction(() {
          this.chatConnection = YouTubeChatConnectionState.error;
          this.chatQuotaExhausted = true;
          this.chatError =
              'YouTube API quota exhausted — chat resumes after the daily reset';
        });
        return;
      } on YouTubeChatEndedException {
        if (superseded()) return;
        runInAction(() {
          this.chatConnection = YouTubeChatConnectionState.offline;
        });
        return;
      } catch (e) {
        if (superseded()) return;
        GeneralHelper.advLog('YouTube chat poll failed — $e');
        runInAction(() {
          this.chatConnection = YouTubeChatConnectionState.error;
          this.chatError = 'Lost connection to YouTube chat';
        });
        return;
      }
      if (superseded()) return;

      backoffMillis = 0;
      lastIntervalMillis = page.pollingIntervalMillis;
      buffer.nextPageToken = page.nextPageToken;
      runInAction(() {
        this.chatConnection = YouTubeChatConnectionState.connected;
        this._applyPageMessages(label, page.messages);
      });

      if (page.offlineAt != null ||
          page.messages.any(
            (m) => m.type == YouTubeChatMessageType.chatEnded,
          )) {
        runInAction(() {
          this.chatConnection = YouTubeChatConnectionState.offline;
        });
        return;
      }

      // Net-of-call pacing: the server interval spans response to next
      // request, so subtract the elapsed request time (floor at 0).
      final waitMillis =
          page.pollingIntervalMillis - callStopwatch.elapsedMilliseconds;
      await this._sleep(
        Duration(milliseconds: waitMillis > 0 ? waitMillis : 0),
      );
    }
  }

  /// Route one poll page: lifecycle events (tombstone / userBanned) mutate
  /// the buffer, everything else appends as a row (deduped by message id —
  /// a local send's [YouTubeChatMessage] is already buffered when its poll
  /// echo arrives).
  void _applyPageMessages(String label, List<YouTubeChatMessage> items) {
    for (final item in items) {
      switch (item.type) {
        case YouTubeChatMessageType.tombstone:
          this._applyTombstone(label, item);
        case YouTubeChatMessageType.userBanned:
          this._applyUserBanned(label, item);
        default:
          if (this.messages.any((message) => message.id == item.id)) {
            continue;
          }
          this.messages.add(item);
          while (this.messages.length > kMaxMessages) {
            this.messages.removeAt(0);
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
    final bannedChannelId =
        event.snippet.userBannedDetails?.bannedUserDetails?.channelId;
    if (bannedChannelId == null || bannedChannelId.isEmpty) return;
    if (!this._moderationKeyIsNew('$label:purge:$bannedChannelId')) return;
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
    }

    this.selectedChannelLabel = label;
    this._persistSelectedChannel();

    this.messages.clear();
    if (label != null) {
      final buffer = this._channelBuffers.putIfAbsent(
        label,
        _ChannelBuffer.new,
      );
      this.messages.addAll(buffer.messages);
      if (this._isProResolver()) {
        this.chatConnection = YouTubeChatConnectionState.connecting;
        this.chatError = null;
        this.chatQuotaExhausted = false;
        final flow = this._pollFlow;
        unawaited(this._pollLoop(label, flow));
      } else {
        /// Hard entitlement gate (mirrors [connectChat]): the selection
        /// is kept, but without Pro no poll loop starts
        this.chatConnection = YouTubeChatConnectionState.idle;
      }
    } else {
      this.chatConnection = YouTubeChatConnectionState.idle;
    }
  }

  /// Re-read the channel list from settings (after the user edited
  /// [SettingsKeys.YouTubeUsernames] outside this store). Channels whose
  /// label vanished drop their buffer; a vanished selection falls back to
  /// none.
  @action
  void reloadChannels() {
    final parsed = this._readChannelsFromSettings();
    this.channels
      ..clear()
      ..addAll(parsed);
    final labels = parsed.map((channel) => channel.label).toSet();
    this._channelBuffers.removeWhere((label, _) => !labels.contains(label));
    if (this.selectedChannelLabel != null &&
        !labels.contains(this.selectedChannelLabel)) {
      unawaited(this.selectChannel(null));
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
      if (selected is String &&
          this.channels.any((channel) => channel.label == selected)) {
        this.selectedChannelLabel = selected;
      }
    } catch (e) {
      GeneralHelper.advLog('YouTube chat selection load failed — $e');
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
            final videoId = extractYouTubeVideoId(value);
            if (videoId != null) {
              parsed.add(YouTubeChatChannel(label: key, videoId: videoId));
            }
          }
        });
      }
    } catch (e) {
      GeneralHelper.advLog('YouTube chat channels load failed — $e');
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
      GeneralHelper.advLog('YouTube chat selection persist failed — $e');
    }
  }

  /// Send a chat message as the signed-in user into the selected channel's
  /// live chat. Returns whether it was delivered — never throws; failures
  /// surface in [sendChatError]. The sent message is appended optimistically;
  /// its poll echo lands as a no-op (id dedup in [_applyPageMessages]).
  @action
  Future<bool> sendChatMessage(String text) async {
    final trimmed = text.trim();
    if (!this.canWrite ||
        trimmed.isEmpty ||
        this.sendingChat ||
        this.chatConnection != YouTubeChatConnectionState.connected) {
      return false;
    }
    final label = this.selectedChannelLabel;
    final liveChatId = this._channelBuffers[label]?.liveChatId;
    if (label == null || liveChatId == null) return false;
    this.sendingChat = true;
    this.sendChatError = null;

    try {
      final token = await this._validAccessToken();
      final sent = await this._chatService.insert(
        accessToken: token,
        liveChatId: liveChatId,
        message: trimmed,
      );
      this.messages.add(sent);
      while (this.messages.length > kMaxMessages) {
        this.messages.removeAt(0);
      }
      return true;
    } on YouTubeApiException catch (e) {
      GeneralHelper.advLog('YouTube chat send failed — $e');
      this.sendChatError = e.message;
      return false;
    } catch (e) {
      GeneralHelper.advLog('YouTube chat send failed — $e');
      this.sendChatError = 'Could not send — try again';
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
    try {
      final token = await this._validAccessToken();
      await this._chatService.delete(accessToken: token, messageId: messageId);
    } on YouTubeApiException catch (e) {
      GeneralHelper.advLog('YouTube message delete failed — $e');
      this.moderationError = e.message;
      return false;
    } catch (e) {
      GeneralHelper.advLog('YouTube message delete failed — $e');
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
    try {
      final token = await this._validAccessToken();
      await this._chatService.ban(
        accessToken: token,
        liveChatId: liveChatId,
        channelId: channelId,
        durationSeconds: durationSeconds,
      );
    } on YouTubeApiException catch (e) {
      GeneralHelper.advLog('YouTube ban failed — $e');
      this.moderationError = e.message;
      return false;
    } catch (e) {
      GeneralHelper.advLog('YouTube ban failed — $e');
      this.moderationError = 'Could not ban the user';
      return false;
    }
    this._moderationKeyIsNew('$label:purge:$channelId');
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
    try {
      final token = await this._validAccessToken();
      await this._chatService.unban(accessToken: token, banId: banId);
    } on YouTubeApiException catch (e) {
      GeneralHelper.advLog('YouTube unban failed — $e');
      this.moderationError = e.message;
      return false;
    } catch (e) {
      GeneralHelper.advLog('YouTube unban failed — $e');
      this.moderationError = 'Could not lift the ban';
      return false;
    }
    return true;
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

  Future<void> _persistAuth(YouTubeToken token, String? channelTitle) async {
    await this._authBox.put(
      YouTubeAuth.kBoxKey,
      YouTubeAuth(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken ?? '',
        expiresAtMs:
            DateTime.now().millisecondsSinceEpoch + token.expiresIn * 1000,
        scopes: token.scope,
        channelTitle: channelTitle,
      ),
    );
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
    });
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
  }

  Future<void> dispose() async {
    this._pollFlow++;
    this._loginFlow++;
    await this._authBoxSub?.cancel();
  }
}
