import 'dart:async';
import 'dart:convert';

import 'package:obs_blade/types/classes/kick/kick_pusher_event.dart';
import 'package:obs_blade/utils/general_helper.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum KickPusherConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

/// Kick's chat realtime transport: a public Pusher socket. After
/// `pusher:connection_established` the service subscribes to
/// `chatrooms.{chatroomId}.v2`, pings every 30s (server activity timeout
/// is 120s) and reconnects with exponential backoff (1s doubling, capped
/// at 30s) until [disconnect]. Decoded app events surface via [onEvent];
/// Pusher protocol frames (`pusher:*`) are handled internally.
///
/// [_channelFactory] and [_sleep] are injectable for tests — same seam
/// idiom as `TwitchEventSubService`.
class KickPusherService {
  /// Kick's public Pusher app key, scraped from their frontend bundle —
  /// unofficial but stable since 2023 (verified 2026). If it ever
  /// rotates, re-scrape it from kick.com's JS bundle; public chatrooms
  /// need no Pusher auth.
  static const String kAppKey = '32cbd69e4b950bf97679';

  static const Duration _pingInterval = Duration(seconds: 30);
  static const Duration _maxBackoff = Duration(seconds: 30);

  final void Function(KickPusherEvent event) onEvent;
  final void Function(KickPusherConnectionState state) onStateChanged;
  final WebSocketChannel Function(Uri) _channelFactory;
  final Future<void> Function(Duration) _sleep;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _socketSub;
  Timer? _pingTimer;

  int? _chatroomId;
  int _reconnectAttempts = 0;
  bool _disposed = false;

  KickPusherService({
    required this.onEvent,
    required this.onStateChanged,
    WebSocketChannel Function(Uri)? channelFactory,
    Future<void> Function(Duration)? sleep,
  }) : _channelFactory = channelFactory ?? WebSocketChannel.connect,
       _sleep = sleep ?? Future.delayed;

  /// (Re)arms the session against [chatroomId] — resets the backoff and
  /// opens the socket. Returns once the socket is initiated; the
  /// connection result arrives via [onStateChanged].
  Future<void> connect({required int chatroomId}) async {
    this._disposed = false;
    this._chatroomId = chatroomId;
    this._reconnectAttempts = 0;
    this._openSocket();
  }

  void _openSocket() {
    final chatroomId = this._chatroomId;
    if (chatroomId == null || this._disposed) return;
    this.onStateChanged(
      this._reconnectAttempts == 0
          ? KickPusherConnectionState.connecting
          : KickPusherConnectionState.reconnecting,
    );
    WebSocketChannel channel;
    try {
      channel = this._channelFactory(
        Uri.parse(
          'wss://ws-us2.pusher.com/app/$kAppKey'
          '?protocol=7&client=js&version=7.6.0&flash=false',
        ),
      );
    } catch (e) {
      GeneralHelper.advLog('Kick pusher connect failed - $e');
      this._scheduleReconnect();
      return;
    }
    this._channel = channel;
    this._socketSub = channel.stream.listen(
      this._onData,
      onError: (Object error) {
        GeneralHelper.advLog('Kick pusher socket error - $error');
        this._onSocketClosed();
      },
      onDone: this._onSocketClosed,
    );
  }

  void _onData(dynamic raw) {
    if (raw is! String) return;
    final event = KickPusherEvent.parse(raw);
    if (event == null) return;
    switch (event.event) {
      case 'pusher:connection_established':
        this._reconnectAttempts = 0;
        this._send(<String, Object?>{
          'event': 'pusher:subscribe',
          'data': <String, Object?>{
            'auth': '',
            'channel': 'chatrooms.${this._chatroomId}.v2',
          },
        });
        this._pingTimer?.cancel();
        this._pingTimer = Timer.periodic(_pingInterval, (_) {
          this._send(<String, Object?>{'event': 'pusher:ping', 'data': {}});
        });
        this.onStateChanged(KickPusherConnectionState.connected);
      case 'pusher:pong':

        /// Keepalive answer — nothing to do.
        break;
      default:

        /// `pusher_internal:subscription_succeeded` etc. stay internal.
        if (!event.event.startsWith('pusher')) {
          this.onEvent(event);
        }
    }
  }

  void _send(Map<String, Object?> payload) {
    try {
      this._channel?.sink.add(json.encode(payload));
    } catch (e) {
      GeneralHelper.advLog('Kick pusher send failed - $e');
    }
  }

  void _onSocketClosed() {
    this._pingTimer?.cancel();
    this._pingTimer = null;
    if (this._disposed) return;
    this._scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (this._disposed) return;
    this._reconnectAttempts++;
    final seconds = 1 << (this._reconnectAttempts - 1);
    final delay = seconds > _maxBackoff.inSeconds
        ? _maxBackoff
        : Duration(seconds: seconds);
    unawaited(
      this._sleep(delay).then((_) {
        if (!this._disposed) this._openSocket();
      }),
    );
  }

  /// Tears the session down permanently (no reconnect) — channel switch
  /// and store disposal both go through here.
  Future<void> disconnect() async {
    this._disposed = true;
    this._pingTimer?.cancel();
    this._pingTimer = null;
    await this._socketSub?.cancel();
    this._socketSub = null;
    try {
      await this._channel?.sink.close();
    } catch (_) {
      // already gone
    }
    this._channel = null;
    this.onStateChanged(KickPusherConnectionState.disconnected);
  }

  Future<void> dispose() => this.disconnect();
}
