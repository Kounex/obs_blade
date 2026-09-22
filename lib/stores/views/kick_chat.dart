import 'dart:async';

import 'package:hive_ce/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/models/kick_auth.dart';
import 'package:obs_blade/stores/pro_store.dart';
import 'package:obs_blade/types/classes/kick/kick_channel.dart';
import 'package:obs_blade/types/classes/kick/kick_chat_message.dart';
import 'package:obs_blade/types/classes/kick/kick_pusher_event.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/general_helper.dart';
import 'package:obs_blade/utils/kick/kick_api_service.dart';
import 'package:obs_blade/types/classes/kick/kick_token.dart';
import 'package:obs_blade/utils/kick/kick_auth_service.dart';
import 'package:obs_blade/utils/kick/kick_channel_service.dart';
import 'package:obs_blade/utils/kick/kick_pusher_service.dart';

part 'kick_chat.g.dart';

enum KickChatConnectionState {
  /// No selected channel (or not started yet).
  idle,
  connecting,
  connected,

  /// Socket dropped, reconnect with backoff in flight (messages stay).
  reconnecting,

  /// The channel does not resolve (bad slug / deleted channel) — not an
  /// error.
  offline,
  error,
}

/// Sign-in lifecycle for the optional Kick account (writes/moderation).
/// Reads are anonymous, so there is no `unconfigured` gating state — a
/// missing OAuth client id only blocks the login start (surfaced as
/// [KickChatStore.authError]).
enum KickAuthState {
  signedOut,

  /// Browser opened with the authorize URL — waiting for the pasted
  /// redirect URL (manual-paste PKCE; Kick has no device flow).
  awaitingRedirect,
  signingIn,
  signedIn,
  error,
}

class KickChatStore = _KickChatStore with _$KickChatStore;

/// In-memory per-channel chat snapshot — swapped in/out of the live
/// [messages] list on selectChannel so switching back restores recent
/// history and skips the backfill. Dies with the app session; never
/// persisted (chat content never touches Hive).
class _ChannelBuffer {
  List<KickChatMessage> messages;
  KickChannelInfo? channelInfo;
  KickChatMessage? pinnedMessage;

  _ChannelBuffer({List<KickChatMessage>? messages, this.channelInfo})
    : messages = messages ?? <KickChatMessage>[];
}

/// Factory seam for the realtime transport — tests substitute a fake
/// pusher; production uses [KickPusherService.new].
typedef KickPusherFactory =
    KickPusherService Function({
      required void Function(KickPusherEvent event) onEvent,
      required void Function(KickPusherConnectionState state) onStateChanged,
    });

/// Owns the native Kick chat: anonymous reads (channel resolution +
/// history backfill over REST, live events over Kick's public Pusher
/// socket) with per-channel buffers, plus the optional signed-in account
/// (manual-paste PKCE OAuth) that unlocks sends/replies and moderation
/// via Kick's official API.
abstract class _KickChatStore with Store {
  static const int kMaxMessages = 500;
  static const Duration kRefreshWindow = Duration(minutes: 5);

  /// Rolling cap for the sent-message id bookkeeping (echo marker).
  static const int kMaxSentIds = 50;

  final KickChannelService _channelService;
  final KickPusherFactory _pusherFactory;
  final KickAuthService _authService;

  /// Assigned in the ctor body — the default instance rides this store's
  /// token lifecycle (refresh + persist), which needs `this`.
  late final KickApiService _apiService;

  /// The live socket session for the selected channel; swapped on
  /// selectChannel, torn down on dispose.
  KickPusherService? _pusher;

  /// Identifies the active connection flow — selectChannel/dispose bump
  /// this so a stale flow's continuations (mid-resolve, mid-backfill or
  /// socket callbacks of the previous channel) bail out.
  int _connectFlow = 0;

  /// Whether [_ensureChannelsLoaded] already ran for this instance —
  /// the settings load is idempotent per store instance.
  bool _channelsLoaded = false;

  /// External wipe watcher (data management clears the auth box).
  StreamSubscription<BoxEvent>? _authBoxSub;

  /// Pending PKCE login between "Open Kick login" and the pasted redirect
  /// URL. In-memory only — a dismissed login simply drops it.
  KickPkceSession? _pendingLogin;

  /// Ids of messages we sent (the `POST /chat` response). There is no
  /// optimistic append — the Pusher echo is the only render path — so the
  /// set only marks own echoes; the id-dedup in [_applyEvent] is the
  /// actual backstop. Insertion-ordered, rolled at [kMaxSentIds].
  final Set<String> _sentMessageIds = <String>{};

  /// Pro entitlement read (test seam) - native chat "just doesn't work"
  /// without Pro: [connectChat] refuses, so neither a persisted engine
  /// selection nor the cold-start auto-select can connect behind the
  /// locked pane.
  final bool Function() _isProResolver;

  _KickChatStore({
    KickChannelService? channelService,
    KickPusherFactory? pusherFactory,
    KickAuthService? authService,
    KickApiService? apiService,
    bool Function()? isProResolver,
  }) : _channelService = channelService ?? KickChannelService(),
       _pusherFactory =
           pusherFactory ??
           (({required onEvent, required onStateChanged}) => KickPusherService(
             onEvent: onEvent,
             onStateChanged: onStateChanged,
           )),
       _authService = authService ?? KickAuthService(),
       _isProResolver =
           isProResolver ?? (() => GetIt.instance<ProStore>().isPro) {
    /// The default API service rides this store's token lifecycle
    /// (refresh + persist); tests inject a fake instead.
    this._apiService =
        apiService ??
        KickApiService(
          tokenProvider: ({required forceRefresh}) =>
              this._validAccessToken(forceRefresh: forceRefresh),
        );
  }

  Box<KickAuth> get _authBox => Hive.box<KickAuth>(HiveKeys.KickAuth.name);

  @observable
  KickChatConnectionState chatConnection = KickChatConnectionState.idle;

  @observable
  String? chatError;

  /// When the current session went live — feeds the connection sheet's
  /// uptime line.
  @observable
  DateTime? chatConnectedAt;

  /// The selected channel's resolution (chatroom modes, live status,
  /// viewer count) — drives the header LIVE chip.
  @observable
  KickChannelInfo? channelInfo;

  /// Native Kick channels — the [SettingsKeys.KickUsernames] slugs (the
  /// WebView list doubles as the native channel list; slug == identity).
  final ObservableList<String> channels = ObservableList<String>();

  /// Currently viewed channel slug, persisted as
  /// [SettingsKeys.SelectedKickUsername] (shared with the WebView path).
  /// Null = no selection.
  @observable
  String? selectedChannelSlug;

  /// Per-channel chat snapshots keyed by slug (in-memory only).
  final Map<String, _ChannelBuffer> _channelBuffers =
      <String, _ChannelBuffer>{};

  final ObservableList<KickChatMessage> messages =
      ObservableList<KickChatMessage>();

  /// Sign-in lifecycle of the optional Kick account (writes/mod).
  @observable
  KickAuthState authState = KickAuthState.signedOut;

  /// Transient auth failure for the setup sheet's inline error line.
  @observable
  String? authError;

  /// A send is in flight — drives the dock's disabled/spinner state and
  /// guards against concurrent sends.
  @observable
  bool sendingChat = false;

  /// Transient send failure for the dock's error line; cleared on the
  /// next attempt.
  @observable
  String? sendChatError;

  /// Transient moderation failure (delete / timeout / ban / unban) the UI
  /// surfaces via snackbar; cleared on the next mod action. Mirrors
  /// YouTubeChatStore.moderationError.
  @observable
  String? modActionError;

  /// The channel's current pin (history `pinned_message`, then live
  /// create/delete events). One pin per channel; swapped with the buffer
  /// on [selectChannel].
  @observable
  KickChatMessage? pinnedMessage;

  /// Reply target for the next sent message (long-press → Reply) — the
  /// full message, so the dock strip can show author + excerpt while the
  /// send forwards its id. Cleared on a successful send and on
  /// [selectChannel]; kept on failure so the user can retry.
  @observable
  KickChatMessage? replyTarget;

  /// Whether a Kick OAuth client id resolves non-empty (BYO setting wins
  /// over the app-owned constant). Gates the login start — reads are
  /// anonymous and unaffected.
  bool get isConfigured => this._authService.resolveClientId().isNotEmpty;

  @computed
  bool get isSignedInState => this.authState == KickAuthState.signedIn;

  /// Whether the persisted token is usable for writes: present, not
  /// expired and carrying the full scope bundle. Deliberately a plain
  /// getter (not reactive): the token changes only at sign-in/sign-out,
  /// which flips [authState] and rebuilds observers.
  bool get isSignedIn {
    final auth = this._authBox.get(KickAuth.kBoxKey);
    return auth != null &&
        !auth.isExpired &&
        kKickChatScopes.every(auth.scopes.contains);
  }

  /// Writes (send / delete / ban) require a signed-in, scoped token.
  bool get canWrite => this.isSignedIn;

  /// Kick user id of the signed-in account (echo-dedup marker).
  int? get selfUserId => this._authBox.get(KickAuth.kBoxKey)?.userId;

  /// Username of the signed-in account (display only).
  String? get selfUsername => this._authBox.get(KickAuth.kBoxKey)?.username;

  /// Profile picture URL of the signed-in account (display only).
  String? get selfProfilePicture =>
      this._authBox.get(KickAuth.kBoxKey)?.profilePicture;

  /// Registers the box watcher (idempotent) so external wipes — e.g.
  /// data management clearing the Kick box — reset the auth state even
  /// when [init] never ran for this instance.
  void _ensureAuthBoxWatcher() {
    this._authBoxSub ??= this._authBox.watch(key: KickAuth.kBoxKey).listen((
      event,
    ) {
      if (event.deleted && this.authState != KickAuthState.signedOut) {
        this._resetToSignedOut();
      }
    });
  }

  void _resetToSignedOut() {
    runInAction(() {
      this._pendingLogin = null;
      this.replyTarget = null;
      this.sendChatError = null;
      this.modActionError = null;
      this.authError = null;
      this.authState = KickAuthState.signedOut;
    });
  }

  /// Cold start: restore channels + selection + a stored session, then
  /// connect (the entitlement gate sits in [connectChat]). Kick has no
  /// cheap token-validation endpoint — a stored record is trusted until a
  /// call 401s it.
  @action
  Future<void> init() async {
    this._ensureAuthBoxWatcher();
    this._ensureChannelsLoaded();
    await this._restoreAuth();
    if (this.selectedChannelSlug == null && this.channels.isNotEmpty) {
      unawaited(this.selectChannel(this.channels.first));
    } else if (this.selectedChannelSlug != null) {
      this.connectChat();
    }
  }

  /// Pick up a stored session: refresh when due; wipe only on a
  /// definitive auth failure (a 400/401/403 on refresh means the refresh
  /// token is dead) — transient 5xx/offline keeps the record.
  Future<void> _restoreAuth() async {
    final auth = this._authBox.get(KickAuth.kBoxKey);
    if (auth == null) {
      this.authState = KickAuthState.signedOut;
      return;
    }
    try {
      await this._validAccessToken();
    } on KickAuthException catch (e) {
      if (e.statusCode == null ||
          e.statusCode == 400 ||
          e.statusCode == 401 ||
          e.statusCode == 403) {
        await this._handleInvalidAuth(
          'Kick session expired — please sign in again',
        );
      } else {
        GeneralHelper.advLog('Kick token refresh on init failed — $e');
        this.authState = KickAuthState.signedOut;
      }
      return;
    }
    this.authState = KickAuthState.signedIn;
  }

  /// Step 1 of login: create the PKCE session, register it with the
  /// exchange host when this build uses the app-owned client, and return
  /// the authorize URL. Null (with [authError] set) when no client id is
  /// configured or the host rejects the registration.
  @action
  Future<Uri?> beginLogin() async {
    if (!this.isConfigured) {
      this.authState = KickAuthState.error;
      this.authError = 'Add your Kick app\'s client id below first';
      return null;
    }
    this._pendingLogin = this._authService.beginSession();
    if (kKickOAuthClientId.isNotEmpty && kKickOAuthClientSecret.isEmpty) {
      try {
        await this._authService.registerProxyLogin(this._pendingLogin!);
      } on KickAuthException catch (e) {
        this._pendingLogin = null;
        this.authState = KickAuthState.error;
        this.authError = e.message;
        return null;
      }
    }
    this.authError = null;
    this.authState = KickAuthState.awaitingRedirect;
    return this._authService.authorizeUrl(this._pendingLogin!);
  }

  /// While the browser is approving: null means still waiting, true means
  /// the exchange host finished and the session is stored, false means
  /// the login failed ([authError] is set).
  @action
  Future<bool?> pollProxyLogin() async {
    final session = this._pendingLogin;
    if (session == null) return false;
    final KickToken token;
    try {
      final polled = await this._authService.pollProxyLogin(session);
      if (polled == null) return null;
      token = polled;
    } on KickAuthException catch (e) {
      this.authState = KickAuthState.error;
      this.authError = e.message;
      return false;
    }
    return this._storeToken(token);
  }

  /// Step 2: the pasted redirect URL → state-checked code → token
  /// exchange → identity fetch → persist. Returns whether the sign-in
  /// completed — never throws; failures land in [authError]/[authState].
  /// The pending session survives failures so a botched paste can be
  /// retried.
  @action
  Future<bool> completeLogin(String pastedRedirectUrl) async {
    final session = this._pendingLogin;
    if (session == null) {
      this.authError = 'Start the login first (Open Kick login)';
      return false;
    }
    final String code;
    try {
      code = this._authService.parseRedirectCode(
        pastedRedirectUrl,
        expectedState: session.state,
      );
    } on KickAuthException catch (e) {
      this.authState = KickAuthState.error;
      this.authError = e.message;
      return false;
    }

    this.authState = KickAuthState.signingIn;
    try {
      final token = await this._authService.exchangeCode(
        code: code,
        session: session,
      );
      return this._storeToken(token);
    } on KickAuthException catch (e) {
      this.authState = KickAuthState.error;
      this.authError = e.message;
      return false;
    } catch (e) {
      GeneralHelper.advLog('Kick login failed unexpectedly — $e');
      this.authState = KickAuthState.error;
      this.authError = 'Unexpected login error';
      return false;
    }
  }

  /// Persist [token] and the account identity. Shared by the paste path
  /// and the exchange-host poll.
  Future<bool> _storeToken(KickToken token) async {
    /// Identity feeds the account chip and the echo-dedup marker — a
    /// fetch failure must not fail the sign-in.
    KickUserIdentity? identity;
    try {
      identity = await this._authService.fetchOwnUser(token.accessToken);
    } catch (e) {
      GeneralHelper.advLog('Kick user fetch failed — $e');
    }
    await this._authBox.put(
      KickAuth.kBoxKey,
      KickAuth(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken ?? '',
        expiresAtMs:
            DateTime.now().millisecondsSinceEpoch + token.expiresIn * 1000,
        scopes: token.scope,
        userId: identity?.userId,
        username: identity?.name,
        profilePicture: identity?.profilePicture,
      ),
    );
    this._pendingLogin = null;
    this.authError = null;
    this.authState = KickAuthState.signedIn;
    return true;
  }

  /// Abandon a pending login (sheet dismissed without pasting).
  @action
  void cancelLogin() {
    this._pendingLogin = null;
    if (this.authState != KickAuthState.signedIn) {
      this.authState = this._authBox.get(KickAuth.kBoxKey) != null
          ? KickAuthState.signedIn
          : KickAuthState.signedOut;
    }
  }

  /// Sign out: wipe the local session, revoke best-effort. Reads are
  /// anonymous, so the chat connection is deliberately untouched.
  @action
  Future<void> logout() async {
    this._pendingLogin = null;
    this.replyTarget = null;
    this.sendingChat = false;
    this.sendChatError = null;
    this.modActionError = null;
    this.authError = null;
    this.authState = KickAuthState.signedOut;
    final auth = this._authBox.get(KickAuth.kBoxKey);
    await this._authBox.delete(KickAuth.kBoxKey);
    if (auth != null) {
      await this._authService.revoke(auth.accessToken);
    }
  }

  /// (Re)start the connection for the selected channel — called after
  /// init and by the UI retry action. Hard entitlement gate: without Pro
  /// the native engine never comes up, no matter which entry point asks
  /// (persisted engine selection, cold-start auto-select, UI retry).
  @action
  void connectChat() {
    if (!this._isProResolver()) return;
    if (this.selectedChannelSlug == null) {
      this.chatConnection = KickChatConnectionState.idle;
      return;
    }
    this._restartConnection();
  }

  void _restartConnection() {
    final slug = this.selectedChannelSlug;
    if (slug == null) return;
    final flow = ++this._connectFlow;
    this._disconnectPusher();
    this.chatConnection = KickChatConnectionState.connecting;
    this.chatError = null;
    unawaited(this._runConnection(slug, flow));
  }

  void _disconnectPusher() {
    final pusher = this._pusher;
    this._pusher = null;
    if (pusher != null) unawaited(pusher.disconnect());
  }

  /// The read pipeline: resolve the slug (cached in the channel buffer),
  /// backfill recent history (best-effort — only into an empty buffer),
  /// then subscribe to `chatrooms.{chatroomId}.v2` via the pusher socket
  /// (which owns keepalive + reconnect). A bumped [_connectFlow]
  /// (selectChannel / dispose) cancels the flow.
  Future<void> _runConnection(String slug, int flow) async {
    final buffer = this._channelBuffers.putIfAbsent(slug, _ChannelBuffer.new);

    bool superseded() =>
        flow != this._connectFlow || slug != this.selectedChannelSlug;

    var info = buffer.channelInfo;
    if (info == null) {
      try {
        info = await this._channelService.resolveChannel(slug);
      } catch (e) {
        if (superseded()) return;
        GeneralHelper.advLog('Kick channel resolve failed — $e');
        runInAction(() {
          this.chatConnection = KickChatConnectionState.error;
          this.chatError = 'Could not resolve the Kick channel';
        });
        return;
      }
      if (superseded()) return;
      if (info == null) {
        /// Unknown slug — a normal state, not an error.
        runInAction(() {
          this.channelInfo = null;
          this.chatConnection = KickChatConnectionState.offline;
        });
        return;
      }
      buffer.channelInfo = info;
    }
    runInAction(() => this.channelInfo = info);

    if (buffer.messages.isEmpty) {
      try {
        final history = await this._channelService.backfillMessages(info.id);
        if (superseded()) return;
        runInAction(() {
          this._applyBackfill(history.messages);
          this.pinnedMessage = history.pinnedMessage;
          buffer.pinnedMessage = history.pinnedMessage;
        });
      } catch (e) {
        if (superseded()) return;

        /// History is a nicety — a failure must not block the live feed.
        GeneralHelper.advLog('Kick chat backfill failed — $e');
      }
    }
    if (superseded()) return;

    final pusher = this._pusherFactory(
      onEvent: (event) {
        if (superseded()) return;
        runInAction(() => this._applyEvent(slug, event));
      },
      onStateChanged: (state) {
        if (superseded()) return;
        runInAction(() {
          switch (state) {
            case KickPusherConnectionState.connected:
              this.chatConnection = KickChatConnectionState.connected;
              this.chatConnectedAt = DateTime.now();
            case KickPusherConnectionState.connecting:
              this.chatConnection = KickChatConnectionState.connecting;
            case KickPusherConnectionState.reconnecting:
              this.chatConnection = KickChatConnectionState.reconnecting;
            case KickPusherConnectionState.disconnected:
              this.chatConnection = KickChatConnectionState.idle;
          }
        });
      },
    );
    this._pusher = pusher;
    await pusher.connect(chatroomId: info.chatroomId);
  }

  /// History lands below any live messages that beat it, deduped by id
  /// (the backfill window overlaps the first live frames).
  void _applyBackfill(List<KickChatMessage> history) {
    for (final message in history) {
      if (this.messages.any((existing) => existing.id == message.id)) {
        continue;
      }
      this.messages.add(message);
    }
    this._trimMessages();
  }

  /// Routes one chatroom event: lifecycle events (delete / ban / clear /
  /// modes update) mutate the buffer, messages append as rows (deduped by
  /// id). A malformed payload is logged and skipped — one bad event must
  /// not break the socket loop.
  void _applyEvent(String slug, KickPusherEvent event) {
    try {
      switch (event.kind) {
        case KickChatroomEventKind.message:
          final message = KickChatMessage.fromJson(event.data);
          if (this.messages.any((existing) => existing.id == message.id)) {
            return;
          }

          /// Own-send echo (bookkeeping only — no optimistic append
          /// exists, so the echo IS the render; the dedup above is the
          /// backstop for socket replays).
          this._sentMessageIds.remove(message.id);
          this.messages.add(message);
          this._trimMessages();
        case KickChatroomEventKind.messageDeleted:
          this._applyMessageDeleted(event);
        case KickChatroomEventKind.userBanned:
          this._applyUserBanned(event);
        case KickChatroomEventKind.chatroomClear:
          this._applyChatroomClear();
        case KickChatroomEventKind.chatroomUpdated:
          this._applyChatroomUpdated(slug, event);
        case KickChatroomEventKind.userUnbanned:

          /// Unbans don't resurrect tombstoned rows.
          break;
        case KickChatroomEventKind.pinnedMessage:
          this._applyPinned(slug, event);
        case KickChatroomEventKind.subscription:
          this._applySubscription(event);
        case KickChatroomEventKind.giftedSubscriptions:
          this._applyGiftedSubscriptions(event);
        case KickChatroomEventKind.streamHost:
          this._applyStreamHost(event);
        case KickChatroomEventKind.unknown:
          break;
      }
    } catch (e) {
      GeneralHelper.advLog(
        'Kick chat event handling failed (${event.event}) — $e',
      );
    }
  }

  void _trimMessages() {
    while (this.messages.length > kMaxMessages) {
      this.messages.removeAt(0);
    }
  }

  /// `MessageDeletedEvent` — mark the buffered copy (dim + marker, same
  /// UX as Twitch); unknown ids are dropped.
  void _applyMessageDeleted(KickPusherEvent event) {
    final messageId = event.deletedMessageId;
    if (messageId == null) return;
    final index = this.messages.indexWhere(
      (message) => message.id == messageId,
    );
    if (index < 0) return;
    this.messages[index] = this.messages[index].copyWith(isTombstoned: true);
  }

  /// `UserBannedEvent` (timeout when `expires_at` is set, permaban when
  /// null — both purge the same way) — tombstone every buffered message
  /// of the banned author (Twitch precedent: purge = tombstone, not
  /// removal).
  void _applyUserBanned(KickPusherEvent event) {
    final userId = event.targetUserId;
    if (userId == null) return;
    for (var i = 0; i < this.messages.length; i++) {
      final message = this.messages[i];
      if (message.sender?.id == userId && !message.isTombstoned) {
        this.messages[i] = message.copyWith(isTombstoned: true);
      }
    }
  }

  /// One pin per channel. Delete clears it; create replaces it with the
  /// nested chat message. A junk create is ignored so a bad frame cannot
  /// wipe a good pin.
  void _applyPinned(String slug, KickPusherEvent event) {
    if (event.isPinDeleted) {
      this.pinnedMessage = null;
    } else {
      final message = event.pinnedChatMessage;
      if (message == null) return;
      this.pinnedMessage = message;
    }
    this._channelBuffers[slug]?.pinnedMessage = this.pinnedMessage;
  }

  /// `ChatroomClearEvent` — drop the buffer and leave a system notice row
  /// (the Twitch engine's `/clear` banner equivalent).
  void _applyChatroomClear() {
    if (this.messages.isEmpty) return;
    this.messages.clear();
    this._appendNotice(
      idPrefix: 'system-clear',
      content: 'Chat was cleared by a moderator',
    );
  }

  /// Appends a synthetic [KickChatMessageType.system] row — shared by
  /// `/clear` and the sub/gift/host notices below. [idPrefix] both
  /// dedupes the icon lookup in the row widget and keeps ids unique.
  void _appendNotice({required String idPrefix, required String content}) {
    this.messages.add(
      KickChatMessage(
        id: '$idPrefix-${DateTime.now().microsecondsSinceEpoch}',
        type: KickChatMessageType.system,
        content: content,
        createdAt: DateTime.now(),
      ),
    );
    this._trimMessages();
  }

  /// `SubscriptionEvent` — reverse-engineered shape (see
  /// [KickChatroomEventKind.subscription]); a missing field means the
  /// shape didn't hold, so the event is dropped rather than showing a
  /// garbled notice.
  void _applySubscription(KickPusherEvent event) {
    final username = event.subscriberUsername;
    final months = event.subscriptionMonths;
    if (username == null || months == null) return;
    this._appendNotice(
      idPrefix: 'system-sub',
      content: months > 1
          ? '$username subscribed — $months months'
          : '$username subscribed',
    );
  }

  /// `GiftedSubscriptionsEvent` — same caveat as [_applySubscription].
  void _applyGiftedSubscriptions(KickPusherEvent event) {
    final gifter = event.gifterUsername;
    final recipients = event.giftedUsernames;
    if (gifter == null || recipients.isEmpty) return;
    this._appendNotice(
      idPrefix: 'system-gift',
      content: recipients.length == 1
          ? '$gifter gifted a sub to ${recipients.first}'
          : '$gifter gifted ${recipients.length} subs',
    );
  }

  /// `StreamHostEvent` — same caveat as [_applySubscription].
  void _applyStreamHost(KickPusherEvent event) {
    final hostUsername = event.hostUsername;
    if (hostUsername == null) return;
    final viewers = event.hostViewerCount;
    this._appendNotice(
      idPrefix: 'system-host',
      content: viewers != null
          ? '$hostUsername is hosting you with $viewers viewers'
          : '$hostUsername is hosting you',
    );
  }

  /// `ChatroomUpdatedEvent` — refresh the cached chatroom modes (payload
  /// is the chatroom object; it may omit the id, so fall back to the
  /// resolved one).
  void _applyChatroomUpdated(String slug, KickPusherEvent event) {
    final info = this.channelInfo;
    if (info == null) return;
    try {
      final chatroom = KickChatroom.fromJson(<String, Object?>{
        'id': info.chatroomId,
        ...event.data,
      });
      final updated = info.copyWith(chatroom: chatroom);
      this.channelInfo = updated;
      this._channelBuffers[slug]?.channelInfo = updated;
    } catch (e) {
      GeneralHelper.advLog('Kick chatroom update parse failed — $e');
    }
  }

  /// Long-press → Reply: target the next sent message at [message]. The
  /// dock strip renders from [replyTarget]; sending forwards its id as
  /// `reply_to_message_id`.
  @action
  void setReplyTarget(KickChatMessage message) => this.replyTarget = message;

  /// Cancel the pending reply (strip ✕, or [selectChannel]).
  @action
  void clearReplyTarget() => this.replyTarget = null;

  /// Send a chat message as the signed-in user into the selected channel.
  /// Returns whether it was delivered — never throws; failures surface in
  /// [sendChatError]. No optimistic append: the Pusher socket echoes own
  /// messages back (`sender.id == selfUserId`); the returned message id
  /// is remembered in [_sentMessageIds] and the id-dedup in [_applyEvent]
  /// is the backstop.
  @action
  Future<bool> sendChatMessage(String text, {String? replyToMessageId}) async {
    final trimmed = text.trim();
    if (!this.canWrite ||
        trimmed.isEmpty ||
        this.sendingChat ||
        this.chatConnection != KickChatConnectionState.connected) {
      return false;
    }
    final broadcasterUserId = this.channelInfo?.userId;
    if (broadcasterUserId == null) return false;
    final reply = this.replyTarget;
    final replyId = replyToMessageId ?? reply?.id;
    this.sendingChat = true;
    this.sendChatError = null;

    try {
      final messageId = await this._apiService.sendMessage(
        broadcasterUserId: broadcasterUserId,
        content: trimmed,
        replyToMessageId: replyId,
      );
      this._rememberSentId(messageId);
      if (reply != null && identical(this.replyTarget, reply)) {
        this.replyTarget = null;
      }
      return true;
    } on KickApiException catch (e) {
      GeneralHelper.advLog('Kick chat send failed — $e');
      this.sendChatError = e.message;
      return false;
    } on KickAuthException catch (e) {
      GeneralHelper.advLog('Kick chat send failed — $e');
      this.sendChatError = e.message;
      return false;
    } catch (e) {
      GeneralHelper.advLog('Kick chat send failed — $e');
      this.sendChatError = 'Could not send — try again';
      return false;
    } finally {
      this.sendingChat = false;
    }
  }

  void _rememberSentId(String messageId) {
    this._sentMessageIds.add(messageId);
    while (this._sentMessageIds.length > kMaxSentIds) {
      this._sentMessageIds.remove(this._sentMessageIds.first);
    }
  }

  /// Long-press mod sheet: delete [messageId] in the selected channel.
  /// Returns whether the server accepted — never throws; failures surface
  /// in [modActionError] (403 = not a mod, surfaced honestly). The Pusher
  /// `MessageDeletedEvent` echo reconciles the buffer (tombstone) — no
  /// local pre-marking.
  @action
  Future<bool> deleteChatMessage(String messageId) async {
    if (!this.canWrite) return false;
    this.modActionError = null;
    try {
      await this._apiService.deleteMessage(messageId: messageId);
      return true;
    } on KickApiException catch (e) {
      GeneralHelper.advLog('Kick message delete failed — $e');
      this.modActionError = e.message;
      return false;
    } on KickAuthException catch (e) {
      GeneralHelper.advLog('Kick message delete failed — $e');
      this.modActionError = e.message;
      return false;
    } catch (e) {
      GeneralHelper.advLog('Kick message delete failed — $e');
      this.modActionError = 'Could not delete the message';
      return false;
    }
  }

  /// Mod sheet: time [userId] out for [durationMinutes] (1..10080) in the
  /// selected channel. Same return/echo contract as [deleteChatMessage]
  /// (the `UserBannedEvent` echo purges the author's buffered messages).
  @action
  Future<bool> timeoutUser(int userId, int durationMinutes) =>
      this._banOrTimeout(userId, durationMinutes: durationMinutes);

  /// Mod sheet: ban [userId] permanently in the selected channel. Same
  /// return/echo contract as [deleteChatMessage].
  @action
  Future<bool> banUser(int userId) => this._banOrTimeout(userId);

  Future<bool> _banOrTimeout(int userId, {int? durationMinutes}) async {
    final broadcasterUserId = this.channelInfo?.userId;
    if (!this.canWrite || broadcasterUserId == null) return false;
    this.modActionError = null;
    try {
      await this._apiService.banUser(
        broadcasterUserId: broadcasterUserId,
        userId: userId,
        durationMinutes: durationMinutes,
      );
      return true;
    } on KickApiException catch (e) {
      GeneralHelper.advLog('Kick ban/timeout failed — $e');
      this.modActionError = e.message;
      return false;
    } on KickAuthException catch (e) {
      GeneralHelper.advLog('Kick ban/timeout failed — $e');
      this.modActionError = e.message;
      return false;
    } catch (e) {
      GeneralHelper.advLog('Kick ban/timeout failed — $e');
      this.modActionError = 'Could not ban the user';
      return false;
    }
  }

  /// Lift a ban / remove a timeout for [userId] in the selected channel.
  /// No local reconcile: unbans don't resurrect tombstoned rows.
  @action
  Future<bool> unbanUser(int userId) async {
    final broadcasterUserId = this.channelInfo?.userId;
    if (!this.canWrite || broadcasterUserId == null) return false;
    this.modActionError = null;
    try {
      await this._apiService.unbanUser(
        broadcasterUserId: broadcasterUserId,
        userId: userId,
      );
      return true;
    } on KickApiException catch (e) {
      GeneralHelper.advLog('Kick unban failed — $e');
      this.modActionError = e.message;
      return false;
    } on KickAuthException catch (e) {
      GeneralHelper.advLog('Kick unban failed — $e');
      this.modActionError = e.message;
      return false;
    } catch (e) {
      GeneralHelper.advLog('Kick unban failed — $e');
      this.modActionError = 'Could not lift the ban';
      return false;
    }
  }

  /// Max recent lines shown on the native chat user card.
  static const int kUserCardMessageCap = 20;

  /// Messages from [userId] in the current channel buffer, newest first
  /// (capped at [kUserCardMessageCap]).
  List<KickChatMessage> messagesForChatter(int userId) {
    final matches = <KickChatMessage>[
      for (final message in this.messages)
        if (message.authorId == userId) message,
    ];
    final start = matches.length > kUserCardMessageCap
        ? matches.length - kUserCardMessageCap
        : 0;
    return matches.sublist(start).reversed.toList();
  }

  /// Best-effort avatar/name lookup for the user card — Kick's official
  /// API only allows looking up another user's profile with a
  /// signed-in reader's token (`user:read`); anonymous readers get no
  /// avatar and fall back to the message-buffer identity only. Null on
  /// any failure, so the card can hide the avatar instead of erroring.
  Future<KickUserIdentity?> fetchUserProfile(int userId) async {
    if (!this.canWrite) return null;
    try {
      return await this._apiService.fetchUser(userId);
    } catch (e) {
      GeneralHelper.advLog('Kick user fetch failed — $e');
      return null;
    }
  }

  /// A usable access token for the API service's token provider —
  /// refreshes (and persists the rotated pair) when due or forced (the
  /// 401 retry path).
  Future<String> _validAccessToken({bool forceRefresh = false}) async {
    final auth = this._authBox.get(KickAuth.kBoxKey);
    if (auth == null) throw const KickAuthException('Not signed in');

    if (forceRefresh || auth.expiresWithin(kRefreshWindow)) {
      final token = await this._authService.refreshToken(auth.refreshToken);
      auth
        ..accessToken = token.accessToken
        /// Kick rotates BOTH tokens on refresh; keep the stored one only
        /// as a defensive fallback.
        ..refreshToken = token.refreshToken ?? auth.refreshToken
        ..expiresAtMs =
            DateTime.now().millisecondsSinceEpoch + token.expiresIn * 1000;
      if (token.scope.isNotEmpty) auth.scopes = token.scope;
      await auth.save();
    }
    return auth.accessToken;
  }

  Future<void> _handleInvalidAuth(String message) async {
    await this._authBox.delete(KickAuth.kBoxKey);
    runInAction(() {
      this._pendingLogin = null;
      this.replyTarget = null;
      this.sendChatError = null;
      this.modActionError = null;
      this.authState = KickAuthState.signedOut;
      this.authError = message;
    });
  }

  /// Multi-chat: switch the visible channel (null = no selection / stop).
  /// Only the visible channel is connected — the old channel's chat
  /// snapshot is buffered in memory and restored on switch-back.
  @action
  Future<void> selectChannel(String? slug) async {
    if (slug == this.selectedChannelSlug) return;

    // Cancel the running flow BEFORE touching state so its continuations
    // cannot write into the new channel's buffer.
    this._connectFlow++;
    this._disconnectPusher();

    final previousSlug = this.selectedChannelSlug;
    if (previousSlug != null) {
      final previous = this._channelBuffers.putIfAbsent(
        previousSlug,
        _ChannelBuffer.new,
      );
      previous.messages = List.of(this.messages);
      previous.pinnedMessage = this.pinnedMessage;
    }

    this.selectedChannelSlug = slug;
    this._persistSelectedChannel();

    this.messages.clear();
    this.chatConnectedAt = null;
    this.chatError = null;

    /// A pending reply target points at a message in the previous
    /// channel — meaningless here.
    this.replyTarget = null;
    this.sendChatError = null;
    this.modActionError = null;
    if (slug != null) {
      final buffer = this._channelBuffers.putIfAbsent(slug, _ChannelBuffer.new);
      this.messages.addAll(buffer.messages);
      this.pinnedMessage = buffer.pinnedMessage;
      this.channelInfo = buffer.channelInfo;
      if (this._isProResolver()) {
        this.chatConnection = KickChatConnectionState.connecting;
        this.chatError = null;
        final flow = this._connectFlow;
        unawaited(this._runConnection(slug, flow));
      } else {
        /// Hard entitlement gate (mirrors [connectChat]): the selection
        /// is kept, but without Pro no connection starts.
        this.chatConnection = KickChatConnectionState.idle;
      }
    } else {
      this.channelInfo = null;
      this.pinnedMessage = null;
      this.chatConnection = KickChatConnectionState.idle;
    }
  }

  /// Re-read the channel list from settings (after the user edited
  /// [SettingsKeys.KickUsernames] outside this store). Slug == identity,
  /// so a re-edited entry simply retires the old slug's buffer. A
  /// vanished selection falls back to none.
  @action
  void reloadChannels() {
    final parsed = this._readChannelsFromSettings();
    final retired = {
      for (final slug in this.channels)
        if (!parsed.contains(slug)) slug,
    };
    final selected = this.selectedChannelSlug;
    final retireSelection =
        selected != null &&
        (retired.contains(selected) || !parsed.contains(selected));
    if (retireSelection) {
      // Invalidate in-flight reads before clearing their visible destination.
      // Do not call selectChannel: it would save the retired messages again.
      this._connectFlow++;
      this._disconnectPusher();
      this.messages.clear();
      this.chatConnectedAt = null;
      this.channelInfo = null;
      this.pinnedMessage = null;
      this.chatConnection = KickChatConnectionState.idle;
      this.chatError = null;
      this.replyTarget = null;
      this.sendChatError = null;
      this.modActionError = null;
    }
    this.channels
      ..clear()
      ..addAll(parsed);
    this._channelBuffers.removeWhere(
      (slug, _) => retired.contains(slug) || !parsed.contains(slug),
    );
    if (retireSelection) {
      this.selectedChannelSlug = null;
      this._persistSelectedChannel();
    }
  }

  /// Idempotent settings load (init): restores [channels] and
  /// [selectedChannelSlug]. Missing keys degrade to empty/null; entries
  /// are re-validated through the slug extractor one by one. A persisted
  /// selection that no longer matches a stored channel falls back to none.
  void _ensureChannelsLoaded() {
    if (this._channelsLoaded) return;
    this._channelsLoaded = true;
    this.channels.addAll(this._readChannelsFromSettings());
    try {
      final selected = Hive.box(
        HiveKeys.Settings.name,
      ).get(SettingsKeys.SelectedKickUsername.name);
      if (selected is String && this.channels.contains(selected)) {
        this.selectedChannelSlug = selected;
      }
    } catch (e) {
      GeneralHelper.advLog('Kick chat selection load failed — $e');
    }
  }

  List<String> _readChannelsFromSettings() {
    final parsed = <String>[];
    try {
      final raw = Hive.box(
        HiveKeys.Settings.name,
      ).get(SettingsKeys.KickUsernames.name, defaultValue: <String>[]);
      if (raw is List) {
        for (final entry in raw) {
          if (entry is String && entry.isNotEmpty && !parsed.contains(entry)) {
            parsed.add(entry);
          }
        }
      }
    } catch (e) {
      GeneralHelper.advLog('Kick chat channels load failed — $e');
    }
    return parsed;
  }

  void _persistSelectedChannel() {
    try {
      final box = Hive.box(HiveKeys.Settings.name);
      if (this.selectedChannelSlug == null) {
        box.delete(SettingsKeys.SelectedKickUsername.name);
      } else {
        box.put(
          SettingsKeys.SelectedKickUsername.name,
          this.selectedChannelSlug,
        );
      }
    } catch (e) {
      GeneralHelper.advLog('Kick chat selection persist failed — $e');
    }
  }

  Future<void> dispose() async {
    this._connectFlow++;
    await this._authBoxSub?.cancel();
    final pusher = this._pusher;
    this._pusher = null;
    if (pusher != null) await pusher.dispose();
  }
}
