import 'dart:async';
import 'dart:convert';

import 'package:obs_blade/types/classes/kick/kick_pusher_event.dart';
import 'package:obs_blade/utils/general_helper.dart';
import 'package:obs_blade/utils/kick/kick_realtime_config_service.dart';
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
  /// Which Pusher app the channel's chat is on - asked on connect and
  /// again after Pusher refused the app (`pusher:error` 4000-4099, e.g.
  /// 4001 "App key ... not in this cluster": Kick moved the chat to a new
  /// key on 2026-10-20). Null (tests) or a failed answer:
  /// [KickPusherApp.fallback]. Public chatrooms need no Pusher auth.
  final Future<KickPusherApp?> Function(int channelId)? appResolver;

  KickPusherApp _app = KickPusherApp.fallback;

  /// Ask [appResolver] before the next socket
  bool _resolveApp = true;

  static const Duration _resolveTimeout = Duration(seconds: 10);

  static const Duration _pingInterval = Duration(seconds: 30);
  static const Duration _maxBackoff = Duration(seconds: 30);

  /// No `pusher:connection_established` this long after opening: the
  /// connect hung - dart:io's `WebSocket.connect` has no timeout, and the
  /// chat stayed "Reconnecting..." for good, nothing in the log (dogfood,
  /// 2026-10-20).
  static const Duration kConnectTimeout = Duration(seconds: 15);

  /// Nothing from the server this long while connected: the socket died
  /// quietly. We ping every 30 s and Pusher pongs at once; pusher-js waits
  /// 30 s for the pong.
  static const Duration kQuietTimeout = Duration(seconds: 60);

  final Duration connectTimeout;
  final Duration quietTimeout;

  final void Function(KickPusherEvent event) onEvent;
  final void Function(KickPusherConnectionState state) onStateChanged;
  final WebSocketChannel Function(Uri) _channelFactory;
  final Future<void> Function(Duration) _sleep;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _socketSub;
  Timer? _pingTimer;

  /// Reconnects a socket that doesn't answer in time ([connectTimeout],
  /// then [quietTimeout] after each frame)
  Timer? _watchdog;
  bool _established = false;

  int? _chatroomId;

  /// The channel's own id — `channel.{id}` carries the stream on/off air
  /// events (`StreamerIsLive` / `StopStreamBroadcast`). Optional.
  int? _channelId;
  int _reconnectAttempts = 0;
  bool _disposed = false;

  /// Bumped by [connect] and [disconnect] — a reconnect scheduled under
  /// an older session must not open a socket into the new one.
  int _session = 0;

  KickPusherService({
    required this.onEvent,
    required this.onStateChanged,
    WebSocketChannel Function(Uri)? channelFactory,
    Future<void> Function(Duration)? sleep,
    this.connectTimeout = kConnectTimeout,
    this.quietTimeout = kQuietTimeout,
    this.appResolver,
  }) : _channelFactory = channelFactory ?? WebSocketChannel.connect,
       _sleep = sleep ?? Future.delayed;

  /// (Re)arms the session against [chatroomId] — resets the backoff and
  /// opens the socket. Returns once the socket is initiated; the
  /// connection result arrives via [onStateChanged].
  Future<void> connect({required int chatroomId, int? channelId}) async {
    this._session++;
    this._disposed = false;
    this._chatroomId = chatroomId;
    this._channelId = channelId;
    this._reconnectAttempts = 0;
    this._resolveApp = true;
    await this._open(this._session);
  }

  /// [_openSocket], asking [appResolver] first when due
  Future<void> _open(int session) async {
    final resolver = this.appResolver;
    final channelId = this._channelId;
    if (this._resolveApp && resolver != null && channelId != null) {
      this._resolveApp = false;
      try {
        final app = await resolver(channelId).timeout(_resolveTimeout);
        if (app != null) this._app = app;
      } catch (e) {
        GeneralHelper.logFailure('Kick realtime config failed', e);
      }
      if (this._disposed || session != this._session) return;
    }
    this._openSocket();
  }

  void _openSocket() {
    final chatroomId = this._chatroomId;
    if (chatroomId == null || this._disposed) return;

    /// Never two sockets side by side — every event would arrive twice.
    this._dropSocket();
    this.onStateChanged(
      this._reconnectAttempts == 0
          ? KickPusherConnectionState.connecting
          : KickPusherConnectionState.reconnecting,
    );
    WebSocketChannel channel;
    try {
      channel = this._channelFactory(
        Uri.parse(
          'wss://ws-${this._app.cluster}.pusher.com/app/${this._app.key}'
          '?protocol=7&client=js&version=7.6.0&flash=false',
        ),
      );
    } catch (e) {
      GeneralHelper.logFailure('Kick chat socket connect failed', e);
      this._scheduleReconnect();
      return;
    }
    this._channel = channel;
    this._established = false;
    this._watch(channel, this.connectTimeout);
    this._socketSub = channel.stream.listen(
      (raw) {
        if (!identical(this._channel, channel)) return;
        if (this._established) this._watch(channel, this.quietTimeout);
        this._onData(raw);
      },
      onError: (Object error) {
        GeneralHelper.logFailure('Kick chat socket error', error);
        this._onSocketClosed(channel);
      },
      onDone: () {
        if (identical(this._channel, channel)) {
          GeneralHelper.logFailure(
            'Kick chat socket closed',
            'code ${_closeCode(channel)} - reconnecting',
          );
        }
        this._onSocketClosed(channel);
      },
    );
  }

  static String _closeCode(WebSocketChannel channel) {
    try {
      return '${channel.closeCode} ${channel.closeReason ?? ''}'.trim();
    } catch (_) {
      return 'unknown';
    }
  }

  void _watch(WebSocketChannel channel, Duration window) {
    this._watchdog?.cancel();
    this._watchdog = Timer(window, () {
      if (!identical(this._channel, channel)) return;
      GeneralHelper.logFailure(
        'Kick chat socket stalled',
        '${this._established ? 'no frame' : 'not connected'} within '
            '${window.inSeconds} s - reconnecting',
      );
      this._onSocketClosed(channel);
    });
  }

  /// Closes the current socket (if any) without scheduling a reconnect.
  void _dropSocket() {
    this._pingTimer?.cancel();
    this._pingTimer = null;
    this._watchdog?.cancel();
    this._watchdog = null;
    final sub = this._socketSub;
    final channel = this._channel;
    this._socketSub = null;
    this._channel = null;
    unawaited(sub?.cancel());
    if (channel != null) {
      unawaited(() async {
        try {
          await channel.sink.close();
        } catch (_) {
          // already gone
        }
      }());
    }
  }

  void _onData(dynamic raw) {
    if (raw is! String) return;
    final event = KickPusherEvent.parse(raw);
    if (event == null) return;
    switch (event.event) {
      case 'pusher:connection_established':
        this._reconnectAttempts = 0;
        this._established = true;
        if (this._channel case final channel?) {
          this._watch(channel, this.quietTimeout);
        }
        this._send(<String, Object?>{
          'event': 'pusher:subscribe',
          'data': <String, Object?>{
            'auth': '',
            'channel': 'chatrooms.${this._chatroomId}.v2',
          },
        });

        /// Stream on/off air — community-documented event names, not in
        /// Kick's public docs; best effort (the store's poll covers a
        /// miss).
        if (this._channelId case final channelId?) {
          this._send(<String, Object?>{
            'event': 'pusher:subscribe',
            'data': <String, Object?>{
              'auth': '',
              'channel': 'channel.$channelId',
            },
          });
        }
        this._pingTimer?.cancel();
        this._pingTimer = Timer.periodic(_pingInterval, (_) {
          this._send(<String, Object?>{'event': 'pusher:ping', 'data': {}});
        });
        this.onStateChanged(KickPusherConnectionState.connected);
      case 'pusher:error':

        /// Pusher protocol: 4000-4099 the app config is wrong (the socket
        /// closes) - the next socket asks for the app first
        final data = event.data;
        final code = data['code'];
        GeneralHelper.logFailure(
          'Kick chat socket refused',
          'code $code ${data['message'] ?? ''}'.trim(),
        );
        if (code is num && code >= 4000 && code < 4100) {
          this._resolveApp = true;
        }
      case 'pusher:ping':

        /// Pusher protocol: the server's ping wants a pong
        this._send(<String, Object?>{'event': 'pusher:pong', 'data': {}});
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

  /// A failed socket reports both onError and onDone — only the first
  /// report of the current socket schedules a reconnect.
  void _onSocketClosed(WebSocketChannel channel) {
    if (!identical(this._channel, channel)) return;
    this._dropSocket();
    if (this._disposed) return;
    this._scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (this._disposed) return;
    final session = this._session;
    this._reconnectAttempts++;
    final seconds = 1 << (this._reconnectAttempts - 1);
    final delay = seconds > _maxBackoff.inSeconds
        ? _maxBackoff
        : Duration(seconds: seconds);
    unawaited(
      this._sleep(delay).then((_) {
        if (!this._disposed && session == this._session) {
          return this._open(session);
        }
      }),
    );
  }

  /// Tears the session down permanently (no reconnect) — channel switch
  /// and store disposal both go through here.
  Future<void> disconnect() async {
    this._session++;
    this._disposed = true;
    this._pingTimer?.cancel();
    this._pingTimer = null;
    this._watchdog?.cancel();
    this._watchdog = null;
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
