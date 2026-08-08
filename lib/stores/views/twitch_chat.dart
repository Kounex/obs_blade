import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/stores/views/twitch_badges.dart';
import 'package:obs_blade/stores/views/twitch_emotes.dart';
import 'package:obs_blade/types/classes/twitch/chat_system_notice.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/chat_lifecycle_events.dart';
import 'package:obs_blade/types/classes/twitch/twitch_drop_reason.dart';
import 'package:obs_blade/types/classes/twitch/twitch_token.dart';
import 'package:obs_blade/types/classes/twitch/twitch_user.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/general_helper.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';
import 'package:obs_blade/utils/twitch/twitch_eventsub_service.dart';
import 'package:obs_blade/utils/twitch/twitch_message_service.dart';

part 'twitch_chat.g.dart';

enum TwitchAuthState {
  loggedOut,
  requestingCode,
  awaitingAuthorization,
  loggingIn,
  loggedIn,
  error,
}

enum TwitchChatConnectionState {
  disconnected,
  connecting,
  live,
  reconnecting,
  failed,
}

class TwitchChatStore = _TwitchChatStore with _$TwitchChatStore;

/// Owns the native Twitch chat: device-flow login state, the persisted
/// [TwitchAuth] record and the EventSub-backed message buffer.
abstract class _TwitchChatStore with Store {
  static const int kMaxMessages = 500;
  static const Duration kRefreshWindow = Duration(minutes: 5);

  final TwitchAuthService _authService;
  final TwitchEventSubService Function(
    void Function(ChatMessageEvent) onChatMessage,
    void Function(ChatMessageDeleteEvent) onMessageDelete,
    void Function(ChatClearUserMessagesEvent) onClearUserMessages,
    void Function(ChatClearEvent) onChatClear,
    void Function(String messageId, String actorName) onModerationDelete,
    void Function(TwitchEventSubState) onStateChanged,
    void Function(String) onRevoked,
  ) _eventSubFactory;
  final TwitchBadgeStore Function() _badgeStoreResolver;
  final ThirdPartyEmoteStore Function() _emoteStoreResolver;
  final TwitchEmoteStore Function() _userEmoteStoreResolver;
  final TwitchMessageService _messageService;

  TwitchEventSubService? _eventSub;
  StreamSubscription<BoxEvent>? _authBoxSub;
  bool _loginCancelled = false;

  /// Identifies the active login flow — a superseded flow's stale
  /// continuations (e.g. a poll still mid-sleep) must not touch state.
  int _loginFlow = 0;

  _TwitchChatStore({
    TwitchAuthService? authService,
    TwitchEventSubService Function(
      void Function(ChatMessageEvent),
      void Function(ChatMessageDeleteEvent),
      void Function(ChatClearUserMessagesEvent),
      void Function(ChatClearEvent),
      void Function(String messageId, String actorName),
      void Function(TwitchEventSubState),
      void Function(String),
    )? eventSubFactory,
    TwitchBadgeStore Function()? badgeStoreResolver,
    ThirdPartyEmoteStore Function()? emoteStoreResolver,
    TwitchEmoteStore Function()? userEmoteStoreResolver,
    TwitchMessageService? messageService,
  })  : _authService = authService ?? TwitchAuthService(),
        _eventSubFactory = eventSubFactory ??
            ((onChatMessage, onMessageDelete, onClearUserMessages, onChatClear,
                    onModerationDelete, onStateChanged, onRevoked) =>
                TwitchEventSubService(
                  onChatMessage: onChatMessage,
                  onMessageDelete: onMessageDelete,
                  onClearUserMessages: onClearUserMessages,
                  onChatClear: onChatClear,
                  onModerationDelete: onModerationDelete,
                  onStateChanged: onStateChanged,
                  onRevoked: onRevoked,
                )),
        _badgeStoreResolver = badgeStoreResolver ??
            (() => GetIt.instance<TwitchBadgeStore>()),
        _emoteStoreResolver = emoteStoreResolver ??
            (() => GetIt.instance<ThirdPartyEmoteStore>()),
        _userEmoteStoreResolver = userEmoteStoreResolver ??
            (() => GetIt.instance<TwitchEmoteStore>()),
        _messageService = messageService ?? TwitchMessageService();

  Box<TwitchAuth> get _authBox =>
      Hive.box<TwitchAuth>(HiveKeys.TwitchAuth.name);

  @observable
  TwitchAuthState authState = TwitchAuthState.loggedOut;

  @observable
  String? authError;

  @observable
  String? pendingUserCode;

  @observable
  String? pendingVerificationUri;

  @observable
  TwitchUser? user;

  @observable
  TwitchChatConnectionState chatConnection =
      TwitchChatConnectionState.disconnected;

  @observable
  String? chatError;

  /// When the current chat session went live — drives the connection
  /// sheet's uptime line. In-memory only.
  @observable
  DateTime? chatConnectedAt;

  /// A send is in flight — drives the dock's disabled/spinner state and
  /// guards against concurrent sends.
  @observable
  bool sendingChat = false;

  /// Transient send failure for the dock's error line; cleared on the next
  /// attempt.
  @observable
  String? sendChatError;

  final ObservableList<ChatMessageEvent> messages =
      ObservableList<ChatMessageEvent>();

  /// Ids of visible messages tombstoned by moderation (delete / timeout /
  /// ban / /clear) — plain Set, pruned with the 500-cap. UI reactivity
  /// rides [lifecycleVersion]: rows build inside the window's HiveBuilder
  /// (untracked by the outer Observer), so the version read is the only
  /// rebuild trigger — same pattern as the emote catalogs.
  final Set<String> _deletedMessageIds = <String>{};

  /// Display name of the moderator who deleted a message, keyed by
  /// messageId — plain Map, same [lifecycleVersion] reactivity story as
  /// [_deletedMessageIds]. The actor arrives via `channel.moderate` delete
  /// actions (only when the token carries the moderation scope bundle);
  /// purge and /clear ids never have one.
  final Map<String, String> _deletedMessageActors = <String, String>{};

  /// System banners merged into the scroll by arrival sequence — plain
  /// List, same [lifecycleVersion] reactivity story as [_deletedMessageIds].
  final List<ChatSystemNotice> systemNotices = <ChatSystemNotice>[];

  /// Bumped on every lifecycle mutation (tombstone / banner) — the
  /// window's tracked rebuild signal for the two plain containers above.
  @observable
  int lifecycleVersion = 0;

  /// Monotonic arrival counter — a message at index i has arrival seq
  /// [_arrivalSeq] - messages.length + i + 1 (front eviction shifts
  /// indices, not seqs). Reset on logout/session wipe.
  int _arrivalSeq = 0;

  @computed
  bool get isLoggedIn => this.authState == TwitchAuthState.loggedIn;

  /// Whether the persisted token carries the write scope. Deliberately a
  /// plain getter (not reactive): scopes change only at login/logout, and
  /// those transitions flip [user]/[authState], which rebuild observers.
  bool get canWriteChat =>
      this._authBox.get(TwitchAuth.kBoxKey)?.scopes.contains(
            'user:write:chat',
          ) ??
      false;

  /// Whether the persisted token carries the read-emotes scope (emote
  /// picker). Same deliberately plain (non-reactive) pattern as
  /// [canWriteChat].
  bool get canReadEmotes =>
      this._authBox.get(TwitchAuth.kBoxKey)?.scopes.contains(
            'user:read:emotes',
          ) ??
      false;

  /// Whether the persisted token carries the full moderation read bundle
  /// (`channel.moderate` v2 → deleting-mod reveal). Same deliberately
  /// plain (non-reactive) pattern as [canReadEmotes].
  bool get canReadModeration {
    final scopes = this._authBox.get(TwitchAuth.kBoxKey)?.scopes;
    return scopes != null && kTwitchModerationScopes.every(scopes.contains);
  }

  /// Registers the box watcher (idempotent) so external wipes — e.g.
  /// data management clearing the Twitch box — reset the feature even
  /// when [init] never ran for this instance (fresh login path).
  void _ensureAuthBoxWatcher() {
    this._authBoxSub ??= this
        ._authBox
        .watch(key: TwitchAuth.kBoxKey)
        .listen((event) {
      if (event.deleted && this.authState != TwitchAuthState.loggedOut) {
        this._resetToLoggedOut();
      }
    });
  }

  /// Cold start: validate a stored token (Twitch requires periodic
  /// validation); when still valid, log straight in and connect chat.
  @action
  Future<void> init() async {
    this._ensureAuthBoxWatcher();

    final auth = this._authBox.get(TwitchAuth.kBoxKey);
    if (auth == null) return;

    late final bool valid;
    try {
      valid = await this._authService.validate(auth.accessToken);
    } catch (e) {
      GeneralHelper.advLog('Twitch token validation failed (offline?) — $e');
      return;
    }
    if (!valid) {
      await this._handleInvalidAuth('Twitch session expired — please log in again');
      return;
    }
    this.user = TwitchUser(
      id: auth.userId ?? '',
      login: auth.userLogin ?? '',
      displayName: auth.userDisplayName,
    );
    this.authState = TwitchAuthState.loggedIn;
    await this.connectChat();
  }

  @action
  Future<void> startLogin() async {
    this._loginCancelled = false;
    final flow = ++this._loginFlow;
    this._ensureAuthBoxWatcher();
    this.authError = null;
    this.pendingUserCode = null;
    this.pendingVerificationUri = null;
    this.authState = TwitchAuthState.requestingCode;

    try {
      final deviceCode = await this._authService.requestDeviceCode();
      this.pendingUserCode = deviceCode.userCode;
      this.pendingVerificationUri = deviceCode.verificationUri;
      this.authState = TwitchAuthState.awaitingAuthorization;

      final token = await this._authService.pollForToken(
        deviceCode,
        onPending: () {},
        isCancelled: () => this._loginCancelled || flow != this._loginFlow,
      );

      // A superseded flow must not write state — its stale continuation
      // resumes here before the next isCancelled check would run.
      if (flow != this._loginFlow) return;

      this.authState = TwitchAuthState.loggingIn;
      final user = await this._authService.fetchOwnUser(token.accessToken);
      await this._persistAuth(token, user);
      this.user = user;
      this.pendingUserCode = null;
      this.pendingVerificationUri = null;
      this.authState = TwitchAuthState.loggedIn;
      await this.connectChat();
    } on TwitchAuthException catch (e) {
      // A superseded flow must not clobber the new flow's state.
      if (flow != this._loginFlow) return;
      this.pendingUserCode = null;
      if (this._loginCancelled) {
        // Cancelling an upgrade re-login while a session is live must not
        // misreport it: the persisted auth and the EventSub connection
        // were never torn down, so the store is still logged in.
        this.authState = this.user != null &&
                this._authBox.get(TwitchAuth.kBoxKey) != null
            ? TwitchAuthState.loggedIn
            : TwitchAuthState.loggedOut;
      } else {
        this.authState = TwitchAuthState.error;
        this.authError = e.message;
      }
    } catch (e) {
      if (flow != this._loginFlow) return;
      GeneralHelper.advLog('Twitch login failed unexpectedly — $e');
      this.pendingUserCode = null;
      this.authState = TwitchAuthState.error;
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
    final auth = this._authBox.get(TwitchAuth.kBoxKey);
    await this._disconnectChat();
    this.messages.clear();
    this._clearLifecycle();
    try {
      this._badgeStoreResolver().clear();
    } catch (e) {
      GeneralHelper.advLog('Twitch badge catalog clear failed — $e');
    }
    try {
      this._emoteStoreResolver().clear();
    } catch (e) {
      GeneralHelper.advLog('Third-party emote catalog clear failed — $e');
    }
    try {
      this._userEmoteStoreResolver().clear();
    } catch (e) {
      GeneralHelper.advLog('Twitch user emote catalog clear failed — $e');
    }
    this.user = null;
    this.authState = TwitchAuthState.loggedOut;
    await this._authBox.delete(TwitchAuth.kBoxKey);
    if (auth != null) {
      await this._authService.revoke(auth.accessToken);
    }
  }

  /// (Re)connect the EventSub session — called after login and by the UI
  /// retry action.
  @action
  Future<void> connectChat() async {
    if (this.authState != TwitchAuthState.loggedIn) return;
    this.chatError = null;
    this.chatConnection = TwitchChatConnectionState.connecting;

    try {
      final token = await this._validAccessToken();
      await this._eventSub?.dispose();
      this._eventSub = this._eventSubFactory(
        this._appendMessage,
        (event) => this.applyMessageDelete(event),
        (event) => this.applyClearUserMessages(event.targetUserId),
        (_) => this.applyChatClear(),
        (messageId, actor) => this.applyModerationDelete(messageId, actor),
        this._onEventSubState,
        this._onEventSubRevoked,
      );
      await this._eventSub!.connect(
        accessToken: token,
        userId: this.user!.id,
        broadcasterId: this.user!.id,
        includeModeration: this.canReadModeration,
      );

      /// Badge catalogs are nice-to-have — a fetch problem must never
      /// affect chat, so this is fire-and-forget with logged failures.
      try {
        unawaited(
          this
              ._badgeStoreResolver()
              .fetch(accessToken: token, broadcasterId: this.user!.id)
              .catchError((Object e) {
            GeneralHelper.advLog('Twitch badge fetch failed — $e');
          }),
        );
      } catch (e) {
        GeneralHelper.advLog('Twitch badge fetch could not start — $e');
      }

      /// Third-party emote catalogs (7TV/BTTV) — same nice-to-have,
      /// fire-and-forget policy as badges. Skipped entirely when the
      /// user disabled them (no third-party contact at all). The whole
      /// block is guarded: a missing Settings box or store lookup must
      /// never break the chat connect.
      try {
        if (Hive.box(HiveKeys.Settings.name).get(
          SettingsKeys.TwitchChatThirdPartyEmotes.name,
          defaultValue: true,
        )) {
          unawaited(
            this
                ._emoteStoreResolver()
                .fetch(broadcasterId: this.user!.id)
                .catchError((Object e) {
              GeneralHelper.advLog('Third-party emote fetch failed — $e');
            }),
          );
        }
      } catch (e) {
        GeneralHelper.advLog('Third-party emote fetch could not start — $e');
      }

      /// First-party emote catalog (picker) — same nice-to-have,
      /// fire-and-forget policy as badges. Skipped entirely when the
      /// persisted token predates the read-emotes scope (pre-upgrade
      /// session — the picker shows a re-login CTA instead).
      try {
        if (this.canReadEmotes) {
          unawaited(
            this
                ._userEmoteStoreResolver()
                .fetch(
                  accessToken: token,
                  userId: this.user!.id,
                  broadcasterId: this.user!.id,
                )
                .catchError((Object e) {
              GeneralHelper.advLog('Twitch user emote fetch failed — $e');
            }),
          );
        }
      } catch (e) {
        GeneralHelper.advLog('Twitch user emote fetch could not start — $e');
      }
    } on TwitchAuthException catch (e) {
      // Wipe the stored session only on a definitive auth failure: a
      // 401/403 on refresh means the refresh token is dead, and a null
      // status is our own pre-flight "Not logged in" throw. Anything else
      // (e.g. a 5xx during a Twitch incident) is transient — keep the
      // session and surface a generic connection failure instead.
      if (e.statusCode == null || e.statusCode == 401 || e.statusCode == 403) {
        await this._handleInvalidAuth(e.message);
      } else {
        GeneralHelper.advLog('Twitch chat connect failed — $e');
        this.chatConnection = TwitchChatConnectionState.failed;
        this.chatError = 'Could not connect to Twitch chat';
        this.chatConnectedAt = null;
      }
    } catch (e) {
      GeneralHelper.advLog('Twitch chat connect failed — $e');
      this.chatConnection = TwitchChatConnectionState.failed;
      this.chatError = 'Could not connect to Twitch chat';
      this.chatConnectedAt = null;
    }
  }

  /// Send a chat message as the logged-in user into their own channel.
  /// Returns whether it was delivered — never throws; failures surface in
  /// [sendChatError]. The sent message renders via the EventSub echo.
  @action
  Future<bool> sendChatMessage(String text) async {
    final trimmed = text.trim();
    if (this.authState != TwitchAuthState.loggedIn ||
        !this.canWriteChat ||
        trimmed.isEmpty ||
        this.sendingChat) {
      return false;
    }
    this.sendingChat = true;
    this.sendChatError = null;

    try {
      final token = await this._validAccessToken();
      final result = await this._messageService.sendChatMessage(
        accessToken: token,
        senderId: this.user!.id,
        broadcasterId: this.user!.id,
        message: trimmed,
      );
      if (result.isSent) return true;
      this.sendChatError = _dropReasonText(result.dropReason);
      return false;
    } catch (e) {
      GeneralHelper.advLog('Twitch chat send failed — $e');
      this.sendChatError = 'Could not send — try again';
      return false;
    } finally {
      this.sendingChat = false;
    }
  }

  /// Human text for Helix `drop_reason` objects (200-but-dropped sends).
  /// Twitch's code list is open-ended (documented example:
  /// `channel_settings_block`) — unknown codes surface Twitch's own
  /// message when it carries one.
  static String _dropReasonText(TwitchDropReason? dropReason) {
    if (dropReason == null) return 'Message not delivered';
    return switch (dropReason.code) {
      'automod_blocked' || 'automod_held' => 'Message held by AutoMod',
      'duplicate' => 'Duplicate message',
      'rate_limited' => 'Sending too fast — slow down',
      _ => (dropReason.message?.isNotEmpty ?? false)
          ? dropReason.message!
          : 'Message not delivered (${dropReason.code})',
    };
  }

  Future<String> _validAccessToken() async {
    final auth = this._authBox.get(TwitchAuth.kBoxKey);
    if (auth == null) throw const TwitchAuthException('Not logged in');

    if (auth.expiresWithin(kRefreshWindow)) {
      final token = await this._authService.refreshToken(auth.refreshToken);
      auth
        ..accessToken = token.accessToken
        ..refreshToken = token.refreshToken ?? auth.refreshToken
        ..expiresAtMs = DateTime.now().millisecondsSinceEpoch +
            token.expiresIn * 1000;
      await auth.save();
    }
    return auth.accessToken;
  }

  Future<void> _persistAuth(TwitchToken token, TwitchUser user) async {
    await this._authBox.put(
      TwitchAuth.kBoxKey,
      TwitchAuth(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken ?? '',
        expiresAtMs:
            DateTime.now().millisecondsSinceEpoch + token.expiresIn * 1000,
        scopes: token.scope,
        userId: user.id,
        userLogin: user.login,
        userDisplayName: user.displayName,
      ),
    );
  }

  @action
  void _appendMessage(ChatMessageEvent event) {
    this.messages.add(event);
    this._arrivalSeq++;
    while (this.messages.length > kMaxMessages) {
      this._deletedMessageIds.remove(this.messages.first.messageId);
      this._deletedMessageActors.remove(this.messages.first.messageId);
      this.messages.removeAt(0);
    }
  }

  /// Test seam — the store's message intake is normally fed by the
  /// EventSub service callback.
  @action
  void appendChatMessageForTest(ChatMessageEvent event) =>
      this._appendMessage(event);

  /// Whether [messageId] is tombstoned — plain read (reactivity rides
  /// [lifecycleVersion]).
  bool isMessageDeleted(String messageId) =>
      this._deletedMessageIds.contains(messageId);

  /// Display name of the moderator who deleted [messageId] — null for
  /// purges, /clear, and unknown/untombstoned ids. Plain read (reactivity
  /// rides [lifecycleVersion]).
  String? deletedMessageActor(String messageId) =>
      this._deletedMessageActors[messageId];

  /// Visible messages + system notices in arrival order — the window's
  /// single render source. A notice sorts after every message with
  /// seq <= afterSeq; front eviction drops old seqs naturally.
  List<Object> messagesWithNotices() {
    if (this.systemNotices.isEmpty) return List.of(this.messages);
    final base = this._arrivalSeq - this.messages.length + 1;
    final merged = <Object>[];
    var noticeIndex = 0;
    for (var i = 0; i < this.messages.length; i++) {
      final seq = base + i;
      while (noticeIndex < this.systemNotices.length &&
          this.systemNotices[noticeIndex].afterSeq < seq) {
        merged.add(this.systemNotices[noticeIndex]);
        noticeIndex++;
      }
      merged.add(this.messages[i]);
    }
    while (noticeIndex < this.systemNotices.length) {
      merged.add(this.systemNotices[noticeIndex]);
      noticeIndex++;
    }
    return merged;
  }

  /// Moderation lifecycle — all idempotent; events for unknown/evicted
  /// ids are no-ops. [lifecycleVersion] bumps only on real mutations.
  @action
  void applyMessageDelete(ChatMessageDeleteEvent event) {
    final visible = this
        .messages
        .any((message) => message.messageId == event.messageId);
    if (visible && this._deletedMessageIds.add(event.messageId)) {
      final actor = event.userName;
      if (actor != null) {
        this._deletedMessageActors[event.messageId] = actor;
      }
      this.lifecycleVersion++;
    }
  }

  /// `channel.moderate` delete — tombstone + actor in one event (a
  /// superset of `message_delete`). Both orderings converge: the version
  /// bumps on any real change, so a `message_delete`-first tombstone gains
  /// its actor (and tap target) when this lands; a moderate-first
  /// tombstone makes the later `message_delete` a no-op.
  @action
  void applyModerationDelete(String messageId, String actorName) {
    final visible =
        this.messages.any((message) => message.messageId == messageId);
    if (!visible) return;
    final tombstoned = this._deletedMessageIds.add(messageId);
    final actorNew = this._deletedMessageActors[messageId] != actorName;
    if (actorNew) this._deletedMessageActors[messageId] = actorName;
    if (tombstoned || actorNew) this.lifecycleVersion++;
  }

  @action
  void applyClearUserMessages(String targetUserId) {
    var changed = false;
    for (final message in this.messages) {
      if (message.chatterUserId == targetUserId &&
          this._deletedMessageIds.add(message.messageId)) {
        changed = true;
      }
    }
    if (changed) this.lifecycleVersion++;
  }

  /// `/clear` on an empty chat is a full no-op — nothing was deleted, so
  /// nothing is marked (and the window's empty-states stay correct).
  @action
  void applyChatClear() {
    if (this.messages.isEmpty) return;
    for (final message in this.messages) {
      this._deletedMessageIds.add(message.messageId);
    }
    this.systemNotices.add(
      ChatSystemNotice(
        afterSeq: this._arrivalSeq,
        kind: ChatSystemNoticeKind.chatCleared,
      ),
    );
    this.lifecycleVersion++;
  }

  /// Lifecycle wipe shared by logout and external session resets.
  void _clearLifecycle() {
    this._deletedMessageActors.clear();
    this._deletedMessageIds.clear();
    this.systemNotices.clear();
    this._arrivalSeq = 0;
  }

  void _onEventSubState(TwitchEventSubState state) {
    runInAction(() {
      switch (state) {
        case TwitchEventSubState.connected:
          if (this.chatConnection != TwitchChatConnectionState.live) {
            this.chatConnectedAt = DateTime.now();
          }
          this.chatConnection = TwitchChatConnectionState.live;
          break;
        case TwitchEventSubState.connecting:
          this.chatConnection = TwitchChatConnectionState.connecting;
          break;
        case TwitchEventSubState.reconnecting:
          this.chatConnection = TwitchChatConnectionState.reconnecting;
          break;
        case TwitchEventSubState.disconnected:
          this.chatConnection = TwitchChatConnectionState.disconnected;
          this.chatConnectedAt = null;
          break;
      }
    });
  }

  void _onEventSubRevoked(String reason) {
    if (reason.contains('authorization_revoked') ||
        reason.contains('user_removed') ||
        reason.startsWith('subscription_failed:401')) {
      this._handleInvalidAuth(
          'Twitch access was revoked — please log in again');
    } else {
      runInAction(() {
        this.chatConnection = TwitchChatConnectionState.failed;
        this.chatError = 'Twitch chat subscription failed ($reason)';
        this.chatConnectedAt = null;
      });
    }
  }

  Future<void> _handleInvalidAuth(String message) async {
    await this._disconnectChat();
    await this._authBox.delete(TwitchAuth.kBoxKey);
    runInAction(() {
      this.user = null;
      this.authState = TwitchAuthState.loggedOut;
      this.authError = message;
    });
  }

  void _resetToLoggedOut() {
    runInAction(() {
      this.messages.clear();
      this._clearLifecycle();
      this.user = null;
      this.authState = TwitchAuthState.loggedOut;
    });
    this._disconnectChat();
  }

  Future<void> _disconnectChat() async {
    final eventSub = this._eventSub;
    this._eventSub = null;
    await eventSub?.dispose();
    runInAction(() {
      this.chatConnection = TwitchChatConnectionState.disconnected;
      this.chatConnectedAt = null;
    });
  }

  Future<void> dispose() async {
    await this._authBoxSub?.cancel();
    await this._disconnectChat();
  }
}
