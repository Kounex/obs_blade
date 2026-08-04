import 'dart:async';

import 'package:hive_ce/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/twitch_token.dart';
import 'package:obs_blade/types/classes/twitch/twitch_user.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/utils/general_helper.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';
import 'package:obs_blade/utils/twitch/twitch_eventsub_service.dart';

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
    void Function(TwitchEventSubState) onStateChanged,
    void Function(String) onRevoked,
  ) _eventSubFactory;

  TwitchEventSubService? _eventSub;
  StreamSubscription<BoxEvent>? _authBoxSub;
  bool _loginCancelled = false;

  _TwitchChatStore({
    TwitchAuthService? authService,
    TwitchEventSubService Function(
      void Function(ChatMessageEvent),
      void Function(TwitchEventSubState),
      void Function(String),
    )? eventSubFactory,
  })  : _authService = authService ?? TwitchAuthService(),
        _eventSubFactory = eventSubFactory ??
            ((onChatMessage, onStateChanged, onRevoked) =>
                TwitchEventSubService(
                  onChatMessage: onChatMessage,
                  onStateChanged: onStateChanged,
                  onRevoked: onRevoked,
                ));

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

  final ObservableList<ChatMessageEvent> messages =
      ObservableList<ChatMessageEvent>();

  @computed
  bool get isLoggedIn => this.authState == TwitchAuthState.loggedIn;

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

    final valid = await this._authService.validate(auth.accessToken);
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
        isCancelled: () => this._loginCancelled,
      );

      this.authState = TwitchAuthState.loggingIn;
      final user = await this._authService.fetchOwnUser(token.accessToken);
      await this._persistAuth(token, user);
      this.user = user;
      this.pendingUserCode = null;
      this.pendingVerificationUri = null;
      this.authState = TwitchAuthState.loggedIn;
      await this.connectChat();
    } on TwitchAuthException catch (e) {
      this.pendingUserCode = null;
      if (this._loginCancelled) {
        this.authState = TwitchAuthState.loggedOut;
      } else {
        this.authState = TwitchAuthState.error;
        this.authError = e.message;
      }
    } catch (e) {
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
    final auth = this._authBox.get(TwitchAuth.kBoxKey);
    await this._disconnectChat();
    this.messages.clear();
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
        this._onEventSubState,
        this._onEventSubRevoked,
      );
      await this._eventSub!.connect(
        accessToken: token,
        userId: this.user!.id,
      );
    } on TwitchAuthException catch (e) {
      await this._handleInvalidAuth(e.message);
    } catch (e) {
      GeneralHelper.advLog('Twitch chat connect failed — $e');
      this.chatConnection = TwitchChatConnectionState.failed;
      this.chatError = 'Could not connect to Twitch chat';
    }
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
    while (this.messages.length > kMaxMessages) {
      this.messages.removeAt(0);
    }
  }

  /// Test seam — the store's message intake is normally fed by the
  /// EventSub service callback.
  @action
  void appendChatMessageForTest(ChatMessageEvent event) =>
      this._appendMessage(event);

  void _onEventSubState(TwitchEventSubState state) {
    runInAction(() {
      switch (state) {
        case TwitchEventSubState.connected:
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
    });
  }

  Future<void> dispose() async {
    await this._authBoxSub?.cancel();
    await this._disconnectChat();
  }
}
