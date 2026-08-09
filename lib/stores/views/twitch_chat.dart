import 'dart:async';
import 'dart:collection';

import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/stores/views/twitch_badges.dart';
import 'package:obs_blade/stores/views/twitch_emotes.dart';
import 'package:obs_blade/types/classes/twitch/chat_system_notice.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_notification.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/chat_lifecycle_events.dart';
import 'package:obs_blade/types/classes/twitch/twitch_channel_ref.dart';
import 'package:obs_blade/types/classes/twitch/twitch_drop_reason.dart';
import 'package:obs_blade/types/classes/twitch/twitch_token.dart';
import 'package:obs_blade/types/classes/twitch/twitch_user.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/general_helper.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';
import 'package:obs_blade/utils/twitch/twitch_channel_service.dart';
import 'package:obs_blade/utils/twitch/twitch_eventsub_service.dart';
import 'package:obs_blade/utils/twitch/twitch_message_service.dart';
import 'package:obs_blade/utils/twitch/twitch_moderation_service.dart';

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

/// In-memory per-channel chat snapshot (multi-chat) — swapped in/out of
/// the live containers on `_TwitchChatStore.selectChannel` so switching
/// back restores recent history. Dies with the app session; never
/// persisted (chat content never touches Hive).
class _ChannelBuffer {
  final List<ChatMessageEvent> messages;
  final Set<String> deletedMessageIds;
  final Map<String, String> deletedMessageActors;
  final List<ChatSystemNotice> systemNotices;
  final List<ChatNotificationNotice> chatNotifications;
  final int arrivalSeq;

  const _ChannelBuffer({
    required this.messages,
    required this.deletedMessageIds,
    required this.deletedMessageActors,
    required this.systemNotices,
    required this.chatNotifications,
    required this.arrivalSeq,
  });
}

/// Owns the native Twitch chat: device-flow login state, the persisted
/// [TwitchAuth] record and the EventSub-backed message buffer.
abstract class _TwitchChatStore with Store {
  static const int kMaxMessages = 500;
  static const Duration kRefreshWindow = Duration(minutes: 5);

  final TwitchAuthService _authService;
  final TwitchEventSubService Function(
    void Function(ChatMessageEvent) onChatMessage,
    void Function(ChatNotificationEvent) onChatNotification,
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
  final TwitchChannelService _channelService;
  final TwitchModerationService _moderationService;

  TwitchEventSubService? _eventSub;
  StreamSubscription<BoxEvent>? _authBoxSub;
  bool _loginCancelled = false;

  /// Whether [_loadChannelsFromSettings] already ran for this instance —
  /// the settings load is idempotent per store instance.
  bool _channelsLoaded = false;

  /// Identifies the active login flow — a superseded flow's stale
  /// continuations (e.g. a poll still mid-sleep) must not touch state.
  int _loginFlow = 0;

  _TwitchChatStore({
    TwitchAuthService? authService,
    TwitchEventSubService Function(
      void Function(ChatMessageEvent),
      void Function(ChatNotificationEvent),
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
    TwitchChannelService? channelService,
    TwitchModerationService? moderationService,
  })  : _authService = authService ?? TwitchAuthService(),
        _eventSubFactory = eventSubFactory ??
            ((onChatMessage, onChatNotification, onMessageDelete,
                    onClearUserMessages, onChatClear, onModerationDelete,
                    onStateChanged, onRevoked) =>
                TwitchEventSubService(
                  onChatMessage: onChatMessage,
                  onChatNotification: onChatNotification,
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
        _messageService = messageService ?? TwitchMessageService(),
        _channelService = channelService ?? TwitchChannelService(),
        _moderationService = moderationService ?? TwitchModerationService();

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

  /// Multi-chat: channels the user added (persisted in the settings box as
  /// json maps, [SettingsKeys.NativeChatChannels]). The user's own channel
  /// is never in this list — it is derived from [user].
  final ObservableList<TwitchChannelRef> channels =
      ObservableList<TwitchChannelRef>();

  /// Multi-chat: the currently viewed channel — null means the user's own
  /// channel (the default; persisted as
  /// [SettingsKeys.SelectedNativeChatChannelId]).
  @observable
  String? selectedChannelId;

  /// Whether the effective (selected) channel is currently live — refreshed
  /// on connect/switch and on a light poll. Header LIVE chip.
  @observable
  bool selectedChannelIsLive = false;

  /// Viewer count when [selectedChannelIsLive]; null when offline/unknown.
  @observable
  int? selectedChannelViewerCount;

  Timer? _livePollTimer;

  /// Ids of channels the user moderates (from Get Moderated Channels on
  /// login) — gates the dropdown shields and the mod action sheet.
  final ObservableSet<String> moderatedChannelIds = ObservableSet<String>();

  /// Per-channel chat snapshots keyed by broadcaster id (in-memory only).
  final Map<String, _ChannelBuffer> _channelBuffers =
      <String, _ChannelBuffer>{};

  /// Recently applied moderation keys (deletes / purges / clears) — local
  /// mod actions tombstone immediately and the EventSub echo must not
  /// double-apply (also fixes duplicate `/clear` double-banners). Bounded
  /// FIFO, oldest keys evicted.
  static const int _kMaxAppliedModerationKeys = 256;
  final Set<String> _appliedModerationKeys = <String>{};
  final Queue<String> _appliedModerationOrder = Queue<String>();

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

  /// Chat notifications (subs, streaks, raids…) merged like [systemNotices].
  final List<ChatNotificationNotice> chatNotifications =
      <ChatNotificationNotice>[];

  /// Recent chatter colors for @mention styling — keyed by user id.
  final Map<String, String> _chatterColors = <String, String>{};

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

  /// Whether the persisted token can list the channels the user moderates
  /// (multi-chat: moderated picker section + mod gating). Same
  /// deliberately plain (non-reactive) pattern as [canReadEmotes].
  bool get canReadModeratedChannels =>
      this._authBox.get(TwitchAuth.kBoxKey)?.scopes.contains(
            'user:read:moderated_channels',
          ) ??
      false;

  /// Whether the persisted token can list followed channels (multi-chat:
  /// followed picker section). Same deliberately plain pattern.
  bool get canReadFollows =>
      this._authBox.get(TwitchAuth.kBoxKey)?.scopes.contains(
            'user:read:follows',
          ) ??
      false;

  /// Whether the persisted token carries the mod-action manage scopes
  /// (delete / timeout / ban). Same deliberately plain (non-reactive)
  /// pattern as [canReadModeration].
  bool get canModerateChats {
    final scopes = this._authBox.get(TwitchAuth.kBoxKey)?.scopes;
    return scopes != null &&
        scopes.contains('moderator:manage:chat_messages') &&
        scopes.contains('moderator:manage:banned_users');
  }

  /// The channel chat is read from / sent to — the selected multi-chat
  /// channel or the user's own. Only valid while logged in ([user] set).
  String get effectiveBroadcasterId =>
      this.selectedChannelId ?? this.user!.id;

  /// Null-safe [effectiveBroadcasterId] for moderation dedup keys — the
  /// lifecycle apply methods can run without a login (tests, a session
  /// wipe mid-stream).
  String get effectiveBroadcasterIdSafe =>
      this.selectedChannelId ?? this.user?.id ?? '';

  /// Whether mod actions (delete / timeout / ban) are offered in the
  /// currently selected channel: the token must carry the manage scopes
  /// and the channel must be the user's own (implicit full mod) or one
  /// they moderate.
  bool get canModerateSelectedChannel =>
      this.canModerateChats &&
      (this.selectedChannelId == null ||
          this.moderatedChannelIds.contains(this.selectedChannelId));

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
    this._ensureChannelsLoaded();

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
    this._fetchModeratedChannels();
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
      this._ensureChannelsLoaded();
      this._fetchModeratedChannels();
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
    this._resetMultiChatState();
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
        this._appendNotification,
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
        broadcasterId: this.effectiveBroadcasterId,
        includeModeration: this.canReadModeration,
      );

      this._refetchCatalogs(token, this.effectiveBroadcasterId);
      /// Live poll starts when EventSub reports connected (see
      /// [_onEventSubState]) — not here, so a failed handshake never
      /// leaves a dangling Timer in tests.
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

  void _startLivePoll() {
    this._livePollTimer?.cancel();
    this._livePollTimer =
        Timer.periodic(const Duration(minutes: 1), (_) {
      unawaited(this.refreshSelectedChannelLive());
    });
    unawaited(this.refreshSelectedChannelLive());
  }

  void _stopLivePoll() {
    this._livePollTimer?.cancel();
    this._livePollTimer = null;
    runInAction(() {
      this.selectedChannelIsLive = false;
      this.selectedChannelViewerCount = null;
    });
  }

  /// Best-effort Helix streams check for the effective channel (header
  /// LIVE chip + viewer count). Failures leave the previous value alone.
  @action
  Future<void> refreshSelectedChannelLive() async {
    if (this.authState != TwitchAuthState.loggedIn || this.user == null) {
      this.selectedChannelIsLive = false;
      this.selectedChannelViewerCount = null;
      return;
    }
    try {
      final token = await this._validAccessToken();
      final live = await this._channelService.getLiveBroadcasterIds(
        accessToken: token,
        broadcasterIds: [this.effectiveBroadcasterId],
      );
      final id = this.effectiveBroadcasterId;
      this.selectedChannelIsLive = live.containsKey(id);
      this.selectedChannelViewerCount = live[id];
    } catch (e) {
      GeneralHelper.advLog('Twitch live status refresh failed — $e');
    }
  }

  /// Fire-and-forget catalog refetches for [broadcasterId] — badges,
  /// third-party emotes (when the user left them enabled) and first-party
  /// user emotes (when scoped). All nice-to-have: a fetch problem must
  /// never affect chat, so failures are logged, never surfaced. Shared by
  /// [connectChat] and [selectChannel].
  void _refetchCatalogs(String token, String broadcasterId) {
    try {
      unawaited(
        this
            ._badgeStoreResolver()
            .fetch(accessToken: token, broadcasterId: broadcasterId)
            .catchError((Object e) {
          GeneralHelper.advLog('Twitch badge fetch failed — $e');
        }),
      );
    } catch (e) {
      GeneralHelper.advLog('Twitch badge fetch could not start — $e');
    }

    /// Third-party emote catalogs (7TV/BTTV) — skipped entirely when the
    /// user disabled them (no third-party contact at all). The whole block
    /// is guarded: a missing Settings box or store lookup must never break
    /// the chat connect.
    try {
      if (Hive.box(HiveKeys.Settings.name).get(
        SettingsKeys.TwitchChatThirdPartyEmotes.name,
        defaultValue: true,
      )) {
        unawaited(
          this
              ._emoteStoreResolver()
              .fetch(broadcasterId: broadcasterId)
              .catchError((Object e) {
            GeneralHelper.advLog('Third-party emote fetch failed — $e');
          }),
        );
      }
    } catch (e) {
      GeneralHelper.advLog('Third-party emote fetch could not start — $e');
    }

    /// First-party emote catalog (picker) — skipped entirely when the
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
                broadcasterId: broadcasterId,
              )
              .catchError((Object e) {
            GeneralHelper.advLog('Twitch user emote fetch failed — $e');
          }),
        );
      }
    } catch (e) {
      GeneralHelper.advLog('Twitch user emote fetch could not start — $e');
    }
  }

  /// Multi-chat: fetch the channels the user moderates (dropdown shields
  /// + mod gating). Fire-and-forget — mod status is nice-to-have, a
  /// failure degrades to an empty set (no shields, no mod actions), never
  /// to a chat error.
  void _fetchModeratedChannels() {
    if (!this.canReadModeratedChannels || this.user == null) return;
    unawaited(() async {
      try {
        final token = await this._validAccessToken();
        final moderated = await this._channelService.getModeratedChannels(
          accessToken: token,
          userId: this.user!.id,
        );
        runInAction(() {
          this.moderatedChannelIds
            ..clear()
            ..addAll(moderated.map((ref) => ref.id));
        });
      } catch (e) {
        GeneralHelper.advLog('Twitch moderated-channels fetch failed — $e');
      }
    }());
  }

  /// Idempotent settings load (init + fresh login): restores [channels]
  /// and [selectedChannelId]. Missing keys degrade to empty/null; garbage
  /// entries are skipped one by one. A persisted selection that no longer
  /// matches a stored channel falls back to own (null).
  void _ensureChannelsLoaded() {
    if (this._channelsLoaded) return;
    this._channelsLoaded = true;
    try {
      final box = Hive.box(HiveKeys.Settings.name);
      final raw = box.get(
        SettingsKeys.NativeChatChannels.name,
        defaultValue: <dynamic>[],
      );
      if (raw is List) {
        for (final entry in raw) {
          try {
            if (entry is Map) {
              this.channels.add(
                    TwitchChannelRef.fromJson(
                      Map<String, Object?>.from(entry),
                    ),
                  );
            }
          } catch (_) {
            // garbage entry — skipped, the rest still load
          }
        }
      }
      final selected = box.get(SettingsKeys.SelectedNativeChatChannelId.name);
      if (selected is String &&
          this.channels.any((ref) => ref.id == selected)) {
        this.selectedChannelId = selected;
      }
    } catch (e) {
      GeneralHelper.advLog('Multi-chat settings load failed — $e');
    }
  }

  void _persistChannels() {
    try {
      Hive.box(HiveKeys.Settings.name).put(
        SettingsKeys.NativeChatChannels.name,
        [for (final ref in this.channels) ref.toJson()],
      );
    } catch (e) {
      GeneralHelper.advLog('Multi-chat channel persist failed — $e');
    }
  }

  void _persistSelectedChannel() {
    try {
      final box = Hive.box(HiveKeys.Settings.name);
      if (this.selectedChannelId == null) {
        box.delete(SettingsKeys.SelectedNativeChatChannelId.name);
      } else {
        box.put(
          SettingsKeys.SelectedNativeChatChannelId.name,
          this.selectedChannelId,
        );
      }
    } catch (e) {
      GeneralHelper.advLog('Multi-chat selection persist failed — $e');
    }
  }

  /// Multi-chat: add a channel and switch to it (adding expresses intent
  /// to view). Dedupes by channel id; persists the list.
  @action
  Future<void> addChannel(TwitchChannelRef ref) async {
    if (!this.channels.contains(ref)) {
      this.channels.add(ref);
      this._persistChannels();
    }
    await this.selectChannel(ref.id);
  }

  /// Multi-chat: drop a channel (and its in-memory buffer); removing the
  /// selected channel falls back to the user's own. The buffer drop runs
  /// AFTER the fallback switch — the switch re-snapshots the current
  /// channel on its way out.
  @action
  Future<void> removeChannel(String id) async {
    this.channels.removeWhere((ref) => ref.id == id);
    this._persistChannels();
    if (this.selectedChannelId == id) {
      await this.selectChannel(null);
    }
    this._channelBuffers.remove(id);
  }

  /// Multi-chat: switch the visible channel (null = own). Only the
  /// visible channel holds live EventSub subscriptions — the switch
  /// happens on the same websocket session; the old channel's chat
  /// snapshot is buffered in memory and restored on switch-back.
  @action
  Future<void> selectChannel(String? id) async {
    if (id == this.selectedChannelId ||
        this.authState != TwitchAuthState.loggedIn ||
        this.user == null) {
      return;
    }
    final previousBroadcasterId = this.effectiveBroadcasterId;
    final newBroadcasterId = id ?? this.user!.id;

    this._channelBuffers[previousBroadcasterId] = _ChannelBuffer(
      messages: List.of(this.messages),
      deletedMessageIds: Set.of(this._deletedMessageIds),
      deletedMessageActors: Map.of(this._deletedMessageActors),
      systemNotices: List.of(this.systemNotices),
      chatNotifications: List.of(this.chatNotifications),
      arrivalSeq: this._arrivalSeq,
    );

    this.selectedChannelId = id;
    this._persistSelectedChannel();

    this.chatConnection = TwitchChatConnectionState.connecting;
    if (this._eventSub != null) {
      try {
        await this._eventSub!.switchChannel(newBroadcasterId);
      } catch (e) {
        /// Switch failed — the pane shows the error state (with retry);
        /// the selection is kept (no silent revert, spec §5).
        GeneralHelper.advLog('Twitch channel switch failed — $e');
        this.chatConnection = TwitchChatConnectionState.failed;
        this.chatError = 'Could not switch to that channel';
        this.chatConnectedAt = null;
      }
    } else {
      /// No live session to move — a full connect targets the effective
      /// broadcaster.
      await this.connectChat();
    }

    final buffer = this._channelBuffers[newBroadcasterId];
    this.messages.clear();
    this._deletedMessageIds.clear();
    this._deletedMessageActors.clear();
    this.systemNotices.clear();
    this.chatNotifications.clear();
    this._chatterColors.clear();
    if (buffer != null) {
      this.messages.addAll(buffer.messages);
      this._deletedMessageIds.addAll(buffer.deletedMessageIds);
      this._deletedMessageActors.addAll(buffer.deletedMessageActors);
      this.systemNotices.addAll(buffer.systemNotices);
      this.chatNotifications.addAll(buffer.chatNotifications);
      this._arrivalSeq = buffer.arrivalSeq;
      for (final message in buffer.messages) {
        final color = message.color;
        if (color != null && color.isNotEmpty) {
          this._chatterColors[message.chatterUserId] = color;
        }
      }
    } else {
      this._arrivalSeq = 0;
    }
    this.lifecycleVersion++;

    try {
      final token = await this._validAccessToken();
      this._refetchCatalogs(token, newBroadcasterId);
    } on TwitchAuthException catch (e) {
      /// Same policy as [connectChat]: a definitively dead token wipes
      /// the session, a transient one is only logged.
      if (e.statusCode == null ||
          e.statusCode == 401 ||
          e.statusCode == 403) {
        await this._handleInvalidAuth(e.message);
      } else {
        GeneralHelper.advLog('Twitch token refresh on switch failed — $e');
      }
    } catch (e) {
      GeneralHelper.advLog('Twitch token refresh on switch failed — $e');
    }
    unawaited(this.refreshSelectedChannelLive());
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

  /// Send a chat message as the logged-in user into the effective
  /// channel (their own, or the selected multi-chat channel). Returns
  /// whether it was delivered — never throws; failures surface in
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
        broadcasterId: this.effectiveBroadcasterId,
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

  /// Mod action sheet: delete [event]'s message in the effective channel.
  /// Returns whether it was applied — never throws; the sheet surfaces a
  /// snackbar on `false`. On success the tombstone is applied locally with
  /// the local user as the actor, and both EventSub echoes
  /// (`channel.chat.message_delete` and the `channel.moderate` delete) are
  /// pre-marked so they land as no-ops.
  @action
  Future<bool> deleteMessage(ChatMessageEvent event) async {
    if (!this.canModerateSelectedChannel || this.user == null) return false;
    try {
      final token = await this._validAccessToken();
      await this._moderationService.deleteChatMessage(
        accessToken: token,
        broadcasterId: this.effectiveBroadcasterId,
        moderatorId: this.user!.id,
        messageId: event.messageId,
      );
    } catch (e) {
      GeneralHelper.advLog('Twitch message delete failed — $e');
      return false;
    }
    this._moderationKeyIsNew(
        '${this.effectiveBroadcasterIdSafe}:delete:${event.messageId}');
    this.applyModerationDelete(
        event.messageId, this.user!.displayName ?? this.user!.login);
    return true;
  }

  /// Mod action sheet: time [targetUserId] out for [durationSeconds] in
  /// the effective channel. Same return/echo contract as [deleteMessage].
  @action
  Future<bool> timeoutUser(String targetUserId, int durationSeconds) =>
      this._banOrTimeout(targetUserId, durationSeconds: durationSeconds);

  /// Mod action sheet: ban [targetUserId] permanently in the effective
  /// channel. Same return/echo contract as [deleteMessage].
  @action
  Future<bool> banUser(String targetUserId) =>
      this._banOrTimeout(targetUserId);

  /// Shared timeout/ban body — the local purge marks the
  /// `clear_user_messages` echo key first, so the EventSub echo of the
  /// timeout/ban lands as a no-op.
  Future<bool> _banOrTimeout(String targetUserId,
      {int? durationSeconds}) async {
    if (!this.canModerateSelectedChannel || this.user == null) return false;
    try {
      final token = await this._validAccessToken();
      await this._moderationService.banUser(
        accessToken: token,
        broadcasterId: this.effectiveBroadcasterId,
        moderatorId: this.user!.id,
        userId: targetUserId,
        durationSeconds: durationSeconds,
      );
    } catch (e) {
      GeneralHelper.advLog('Twitch ban/timeout failed — $e');
      return false;
    }
    this._moderationKeyIsNew(
        '${this.effectiveBroadcasterIdSafe}:purge:$targetUserId');
    this._purgeUserMessages(targetUserId);
    return true;
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
    final color = event.color;
    if (color != null && color.isNotEmpty) {
      this._chatterColors[event.chatterUserId] = color;
    }
    this.messages.add(event);
    this._arrivalSeq++;
    while (this.messages.length > kMaxMessages) {
      this._deletedMessageIds.remove(this.messages.first.messageId);
      this._deletedMessageActors.remove(this.messages.first.messageId);
      this.messages.removeAt(0);
    }
  }

  @action
  void _appendNotification(ChatNotificationEvent event) {
    final color = event.color;
    if (color != null && color.isNotEmpty) {
      this._chatterColors[event.chatterUserId] = color;
    }
    this.chatNotifications.add(
      ChatNotificationNotice(afterSeq: this._arrivalSeq, event: event),
    );
    this.lifecycleVersion++;
  }

  /// Hex color last seen for [userId], if any (`#RRGGBB`).
  String? chatterColor(String userId) => this._chatterColors[userId];

  /// Test seam — the store's message intake is normally fed by the
  /// EventSub service callback.
  @action
  void appendChatMessageForTest(ChatMessageEvent event) =>
      this._appendMessage(event);

  @action
  void appendChatNotificationForTest(ChatNotificationEvent event) =>
      this._appendNotification(event);

  /// Whether [messageId] is tombstoned — plain read (reactivity rides
  /// [lifecycleVersion]).
  bool isMessageDeleted(String messageId) =>
      this._deletedMessageIds.contains(messageId);

  /// Display name of the moderator who deleted [messageId] — null for
  /// purges, /clear, and unknown/untombstoned ids. Plain read (reactivity
  /// rides [lifecycleVersion]).
  String? deletedMessageActor(String messageId) =>
      this._deletedMessageActors[messageId];

  /// Visible messages + system notices + chat notifications in arrival
  /// order — the window's single render source. A banner sorts after every
  /// message whose seq is <= afterSeq; front eviction drops old seqs
  /// naturally.
  List<Object> messagesWithNotices() {
    final banners = <({int afterSeq, Object item})>[
      for (final notice in this.systemNotices)
        (afterSeq: notice.afterSeq, item: notice),
      for (final notice in this.chatNotifications)
        (afterSeq: notice.afterSeq, item: notice),
    ]..sort((a, b) => a.afterSeq.compareTo(b.afterSeq));
    if (banners.isEmpty) return List.of(this.messages);

    final base = this._arrivalSeq - this.messages.length + 1;
    final merged = <Object>[];
    var bannerIndex = 0;
    for (var i = 0; i < this.messages.length; i++) {
      final seq = base + i;
      while (bannerIndex < banners.length &&
          banners[bannerIndex].afterSeq < seq) {
        merged.add(banners[bannerIndex].item);
        bannerIndex++;
      }
      merged.add(this.messages[i]);
    }
    while (bannerIndex < banners.length) {
      merged.add(banners[bannerIndex].item);
      bannerIndex++;
    }
    return merged;
  }

  /// Moderation lifecycle — all idempotent; events for unknown/evicted
  /// ids are no-ops. [lifecycleVersion] bumps only on real mutations.
  /// Duplicate deliveries (and the EventSub echo of a local mod action)
  /// are skipped via the applied-keys dedup.
  @action
  void applyMessageDelete(ChatMessageDeleteEvent event) {
    if (!this._moderationKeyIsNew(
        '${this.effectiveBroadcasterIdSafe}:delete:${event.messageId}')) {
      return;
    }
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
  /// tombstone makes the later `message_delete` a no-op. The dedup key
  /// includes the actor, so the actor-upgrade ordering is never skipped.
  @action
  void applyModerationDelete(String messageId, String actorName) {
    if (!this._moderationKeyIsNew(
        '${this.effectiveBroadcasterIdSafe}:mod-delete:$messageId:$actorName')) {
      return;
    }
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
    if (!this._moderationKeyIsNew(
        '${this.effectiveBroadcasterIdSafe}:purge:$targetUserId')) {
      return;
    }
    this._purgeUserMessages(targetUserId);
  }

  /// Tombstones every visible message of [targetUserId] — the shared body
  /// of the EventSub purge and a local timeout/ban (the local path marks
  /// the dedup key first so the EventSub echo is skipped).
  void _purgeUserMessages(String targetUserId) {
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
  /// Duplicate deliveries of the SAME /clear (same arrival seq) are
  /// deduped so the banner never doubles.
  @action
  void applyChatClear() {
    if (this.messages.isEmpty) return;
    if (!this._moderationKeyIsNew(
        '${this.effectiveBroadcasterIdSafe}:clear:${this._arrivalSeq}')) {
      return;
    }
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
    this.chatNotifications.clear();
    this._chatterColors.clear();
    this._arrivalSeq = 0;
  }

  /// Multi-chat wipe on logout/reset: per-channel buffers, the moderated
  /// set and the moderation dedup keys die with the session; the selection
  /// resets to the user's own channel (the persisted channels list stays
  /// in the settings box for the next login).
  void _resetMultiChatState() {
    this._channelBuffers.clear();
    this.moderatedChannelIds.clear();
    this._appliedModerationKeys.clear();
    this._appliedModerationOrder.clear();
    this.selectedChannelId = null;
    this._stopLivePoll();
    this._persistSelectedChannel();
  }

  void _onEventSubState(TwitchEventSubState state) {
    runInAction(() {
      switch (state) {
        case TwitchEventSubState.connected:
          if (this.chatConnection != TwitchChatConnectionState.live) {
            this.chatConnectedAt = DateTime.now();
          }
          this.chatConnection = TwitchChatConnectionState.live;
          this._startLivePoll();
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
          this._stopLivePoll();
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
      this._resetMultiChatState();
    });
  }

  void _resetToLoggedOut() {
    runInAction(() {
      this.messages.clear();
      this._clearLifecycle();
      this.user = null;
      this.authState = TwitchAuthState.loggedOut;
      this._resetMultiChatState();
    });
    this._disconnectChat();
  }

  Future<void> _disconnectChat() async {
    final eventSub = this._eventSub;
    this._eventSub = null;
    await eventSub?.dispose();
    this._stopLivePoll();
    runInAction(() {
      this.chatConnection = TwitchChatConnectionState.disconnected;
      this.chatConnectedAt = null;
    });
  }

  Future<void> dispose() async {
    await this._authBoxSub?.cancel();
    this._stopLivePoll();
    await this._disconnectChat();
  }
}
