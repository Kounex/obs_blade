import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/eventsub_envelope.dart';
import 'package:obs_blade/utils/general_helper.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum TwitchEventSubState { disconnected, connecting, connected, reconnecting }

/// Dedicated EventSub WebSocket session for `channel.chat.message`.
/// Completely separate from the OBS WebSocket — owns its socket, keepalive
/// watchdog and reconnect backoff. [channelFactory] and [sleep] are
/// injectable for tests.
class TwitchEventSubService {
  static const String _wsUrl =
      'wss://eventsub.wss.twitch.tv/ws?keepalive_timeout_seconds=30';
  static const String _subscriptionsUrl =
      'https://api.twitch.tv/helix/eventsub/subscriptions';

  /// No message (not even a keepalive) for this long → treat as dead
  static const Duration _watchdogWindow = Duration(seconds: 75);
  static const Duration _maxBackoff = Duration(seconds: 30);

  final http.Client _client;
  final WebSocketChannel Function(Uri) _channelFactory;
  final Future<void> Function(Duration) _sleep;

  final void Function(ChatMessageEvent event) onChatMessage;
  final void Function(TwitchEventSubState state) onStateChanged;

  /// Subscription revoked by Twitch (e.g. `authorization_revoked`) or
  /// creation failed (`subscription_failed:<status>`)
  final void Function(String reason) onRevoked;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _socketSub;
  Timer? _watchdog;

  String? _accessToken;
  String? _userId;
  String? _sessionId;
  String? _subscriptionId;
  int _reconnectAttempts = 0;
  bool _disposed = false;

  TwitchEventSubService({
    required this.onChatMessage,
    required this.onStateChanged,
    required this.onRevoked,
    http.Client? client,
    WebSocketChannel Function(Uri)? channelFactory,
    Future<void> Function(Duration)? sleep,
  })  : _client = client ?? http.Client(),
        _channelFactory = channelFactory ?? WebSocketChannel.connect,
        _sleep = sleep ?? Future.delayed;

  Future<void> connect({
    required String accessToken,
    required String userId,
  }) async {
    this._accessToken = accessToken;
    this._userId = userId;
    this._disposed = false;
    this._reconnectAttempts = 0;
    this._openSocket(Uri.parse(_wsUrl));
  }

  void _openSocket(Uri uri) {
    if (this._disposed) return;
    this.onStateChanged(
      this._reconnectAttempts == 0
          ? TwitchEventSubState.connecting
          : TwitchEventSubState.reconnecting,
    );
    this._channel = this._channelFactory(uri);
    this._socketSub = this._channel!.stream.listen(
      this._handleRawMessage,
      onDone: this._handleDisconnect,
      onError: (_) => this._handleDisconnect(),
      cancelOnError: true,
    );
    this._resetWatchdog();
  }

  void _handleRawMessage(dynamic raw) {
    this._resetWatchdog();

    Map<String, dynamic> decoded;
    try {
      decoded = json.decode(raw as String) as Map<String, dynamic>;
    } catch (e) {
      GeneralHelper.advLog('Twitch EventSub: undecodable message — $e');
      return;
    }

    final envelope = EventSubEnvelope.fromJson(decoded);
    switch (envelope.metadata.messageType) {
      case 'session_welcome':
        this._handleWelcome(envelope.payload);
        break;
      case 'session_keepalive':
        break; // watchdog already reset
      case 'notification':
        this._handleNotification(envelope);
        break;
      case 'session_reconnect':
        this._handleReconnectRequest(envelope.payload);
        break;
      case 'revocation':
        this._handleRevocation(envelope.payload);
        break;
      default:
        GeneralHelper.advLog(
          'Twitch EventSub: unknown message_type '
          '${envelope.metadata.messageType}',
        );
    }
  }

  Future<void> _handleWelcome(Map<String, Object?> payload) async {
    final session = payload['session'] as Map<String, dynamic>;
    final sessionId = session['id'] as String;
    final resumed = sessionId == this._sessionId && this._subscriptionId != null;
    this._sessionId = sessionId;
    this._reconnectAttempts = 0;
    this.onStateChanged(TwitchEventSubState.connected);

    /// A socket opened from `session_reconnect`'s reconnect_url resumes the
    /// session with subscriptions intact — only subscribe on fresh sessions.
    if (!resumed) {
      await this._createSubscription();
    }
  }

  void _handleNotification(EventSubEnvelope envelope) {
    if (envelope.metadata.subscriptionType != 'channel.chat.message') return;
    try {
      this.onChatMessage(
        ChatMessageEvent.fromJson(
          envelope.payload['event'] as Map<String, Object?>,
        ),
      );
    } catch (e) {
      GeneralHelper.advLog('Twitch EventSub: could not parse chat event — $e');
    }
  }

  void _handleReconnectRequest(Map<String, Object?> payload) {
    final session = payload['session'] as Map<String, dynamic>;
    final reconnectUrl = session['reconnect_url'] as String?;
    if (reconnectUrl == null) {
      this._handleDisconnect();
      return;
    }
    this._closeSocket();
    this._openSocket(Uri.parse(reconnectUrl));
  }

  void _handleRevocation(Map<String, Object?> payload) {
    final subscription = payload['subscription'] as Map<String, dynamic>;
    this.onRevoked(subscription['status'] as String? ?? 'revoked');
  }

  Future<void> _createSubscription() async {
    final token = this._accessToken;
    final userId = this._userId;
    final sessionId = this._sessionId;
    if (token == null || userId == null || sessionId == null) return;

    /// The socket-level failure path (DNS/socket/timeout) must not escape
    /// this unawaited future — surface it like a failed subscription.
    try {
      final response = await this._client.post(
        Uri.parse(_subscriptionsUrl),
        headers: {
          ...TwitchAuthService.helixHeaders(token),
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'type': 'channel.chat.message',
          'version': '1',
          'condition': {'broadcaster_user_id': userId, 'user_id': userId},
          'transport': {'method': 'websocket', 'session_id': sessionId},
        }),
      );

      if (response.statusCode == 202) {
        final data =
            (json.decode(response.body) as Map<String, dynamic>)['data'];
        this._subscriptionId = (data as List).first['id'] as String?;
      } else {
        this.onRevoked('subscription_failed:${response.statusCode}');
      }
    } catch (e) {
      GeneralHelper.advLog('Twitch EventSub: subscription POST failed — $e');
      this.onRevoked('subscription_failed:$e');
    }
  }

  void _handleDisconnect() {
    if (this._disposed) return;
    this._closeSocket();
    this._reconnectAttempts++;
    this.onStateChanged(TwitchEventSubState.reconnecting);
    final backoff = Duration(
      seconds: (this._reconnectAttempts * 2).clamp(2, _maxBackoff.inSeconds),
    );
    this._sleep(backoff).then((_) {
      if (!this._disposed) this._openSocket(Uri.parse(_wsUrl));
    });
  }

  void _resetWatchdog() {
    this._watchdog?.cancel();
    this._watchdog = Timer(_watchdogWindow, this._handleDisconnect);
  }

  void _closeSocket() {
    this._watchdog?.cancel();
    this._socketSub?.cancel();
    this._socketSub = null;
    this._channel?.sink.close();
    this._channel = null;
  }

  /// Tear down the session. Deleting the subscription is best effort —
  /// Twitch drops it anyway once the session times out.
  Future<void> dispose() async {
    this._disposed = true;
    this._closeSocket();

    final subscriptionId = this._subscriptionId;
    final token = this._accessToken;
    this._subscriptionId = null;
    if (subscriptionId != null && token != null) {
      try {
        await this._client.delete(
          Uri.parse('$_subscriptionsUrl?id=$subscriptionId'),
          headers: TwitchAuthService.helixHeaders(token),
        );
      } catch (_) {
        // best effort
      }
    }
  }
}
