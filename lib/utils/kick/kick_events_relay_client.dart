import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../general_helper.dart';
import 'package:obs_blade/utils/renewing_http_client.dart';

/// OBS Blade's Kick events relay (`tool/kick_events_relay/`). Kick sends
/// follows, KICKs, subs, redemptions and stream status only as webhooks,
/// which a phone can't receive; the relay receives them for channels
/// whose owner signed in here and keeps them 7 days.
const String kKickEventsRelayUrl = String.fromEnvironment(
  'KICK_EVENTS_RELAY_URL',
  defaultValue: 'https://kick-events.obs-blade.com',
);

enum KickRelayState {
  /// Not running (not Pro, not signed in to Kick, or switched off)
  off,

  /// Proving the channel with the Kick token
  registering,
  connecting,

  /// Socket up and the backlog delivered - live from here on
  synced,

  /// Retrying after a network / server problem
  retrying,
}

class KickRelayException implements Exception {
  final int? statusCode;
  final String message;

  const KickRelayException(this.message, {this.statusCode});

  /// The relay doesn't know this session (expired, or the channel was
  /// dropped) - register again.
  bool get isUnknownSession => this.statusCode == 401;

  @override
  String toString() => 'KickRelayException($statusCode): $message';
}

class KickRelaySession {
  final String token;
  final String broadcasterUserId;
  final String username;

  /// Kick accepted every webhook subscription (false: the relay keeps
  /// retrying in the background)
  final bool subscribed;

  const KickRelaySession({
    required this.token,
    required this.broadcasterUserId,
    required this.username,
    required this.subscribed,
  });
}

typedef KickRelaySocketFactory =
    WebSocketChannel Function(Uri uri, Map<String, String> headers);

class KickEventsRelayClient {
  static const Duration _maxBackoff = Duration(seconds: 60);

  final http.Client _client;
  final KickRelaySocketFactory _socketFactory;
  final Future<void> Function(Duration) _sleep;
  final String _baseUrl;

  WebSocketChannel? _socket;
  StreamSubscription<dynamic>? _socketSub;
  bool _running = false;
  int _attempts = 0;

  /// Bumped per [start] / [stop] - a reconnect scheduled by an older run
  /// must not reopen the socket
  int _generation = 0;

  KickEventsRelayClient({
    http.Client? client,
    KickRelaySocketFactory? socketFactory,
    Future<void> Function(Duration)? sleep,
    String baseUrl = kKickEventsRelayUrl,
  }) : _client = client ?? RenewingHttpClient(),
       _socketFactory =
           socketFactory ??
           ((uri, headers) => IOWebSocketChannel.connect(
             uri,
             headers: headers,
             pingInterval: const Duration(seconds: 30),
             connectTimeout: const Duration(seconds: 15),
           )),
       _sleep = sleep ?? Future.delayed,
       _baseUrl = baseUrl;

  /// Prove the channel with the user's Kick access token (used once by
  /// the relay to look up who it belongs to, never stored there).
  Future<KickRelaySession> register(String kickAccessToken) async {
    final http.Response response;
    try {
      response = await this._client
          .post(
            Uri.parse('${this._baseUrl}/v1/session'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'access_token': kickAccessToken}),
          )
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      throw KickRelayException('Relay unreachable - $e');
    }
    if (response.statusCode != 200) {
      throw KickRelayException(
        'Relay refused the session',
        statusCode: response.statusCode,
      );
    }
    final body = json.decode(response.body);
    final token = body is Map ? body['session_token'] : null;
    final userId = body is Map ? body['broadcaster_user_id'] : null;
    if (token is! String || userId == null) {
      throw const KickRelayException('Relay sent no session');
    }
    return KickRelaySession(
      token: token,
      broadcasterUserId: '$userId',
      username: (body['username'] as String?) ?? '',
      subscribed: body['subscribed'] == true,
    );
  }

  /// Sign out of the relay: the last session of a channel makes the relay
  /// unsubscribe it and delete what it kept. Best effort.
  Future<void> unregister(String sessionToken) async {
    try {
      await this._client
          .delete(
            Uri.parse('${this._baseUrl}/v1/session'),
            headers: {'Authorization': 'Bearer $sessionToken'},
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      GeneralHelper.advLog('Kick relay sign-out failed - $e');
    }
  }

  /// Open the event stream from [after] on and keep it open (reconnects
  /// with backoff). [onEvent] gets every `event` frame; [cursor] is read
  /// on every reconnect so nothing already handled is sent again.
  /// [onUnknownSession] fires when the relay no longer knows the session
  /// (the caller registers again and calls [start] with the new token).
  /// [onSubscribed] gets whether Kick accepted every webhook subscription
  /// (on connect, and again when the relay's retry changes it).
  void start({
    required String sessionToken,
    required int Function() cursor,
    required void Function(Map<String, Object?> frame) onEvent,
    required void Function(KickRelayState state) onState,
    required void Function() onUnknownSession,
    void Function(bool subscribed)? onSubscribed,
  }) {
    unawaited(this.stop());
    this._running = true;
    this._attempts = 0;
    final generation = ++this._generation;
    this._onSubscribed = onSubscribed;
    this._open(
      generation,
      sessionToken,
      cursor,
      onEvent,
      onState,
      onUnknownSession,
    );
  }

  void Function(bool subscribed)? _onSubscribed;

  /// The HTTP status a failed WebSocket upgrade was answered with
  static int? upgradeStatus(Object error) {
    final inner = error is WebSocketChannelException ? error.inner : error;
    return inner is WebSocketException ? inner.httpStatusCode : null;
  }

  void _open(
    int generation,
    String sessionToken,
    int Function() cursor,
    void Function(Map<String, Object?>) onEvent,
    void Function(KickRelayState) onState,
    void Function() onUnknownSession,
  ) {
    if (!this._running || generation != this._generation) return;
    onState(KickRelayState.connecting);
    final base = Uri.parse(this._baseUrl);
    final uri = base.replace(
      scheme: base.scheme == 'http' ? 'ws' : 'wss',
      path: '/v1/stream',
      queryParameters: {'after': '${cursor()}'},
    );
    WebSocketChannel socket;
    try {
      socket = this._socketFactory(uri, {
        'Authorization': 'Bearer $sessionToken',
      });
    } catch (e) {
      this._retry(
        generation,
        sessionToken,
        cursor,
        onEvent,
        onState,
        onUnknownSession,
      );
      return;
    }
    this._socket = socket;

    /// A 401 on the upgrade surfaces as a failed `ready`. Its status code,
    /// never its text: that holds the URL, whose cursor can read "401".
    socket.ready.catchError((Object e) {
      if (generation != this._generation) return;
      if (upgradeStatus(e) == 401) {
        this._running = false;
        onState(KickRelayState.off);
        onUnknownSession();
      }
    });
    this._socketSub = socket.stream.listen(
      (raw) {
        if (generation != this._generation) return;
        Object? decoded;
        try {
          decoded = json.decode(raw as String);
        } catch (_) {
          return;
        }
        if (decoded is! Map) return;
        final frame = Map<String, Object?>.from(decoded);
        switch (frame['type']) {
          case 'event':
            onEvent(frame);
          case 'hello' || 'status':
            final subscribed = frame['subscribed'];
            if (subscribed is bool) this._onSubscribed?.call(subscribed);
          case 'synced':
            this._attempts = 0;
            onState(KickRelayState.synced);
        }
      },
      onDone: () => this._retry(
        generation,
        sessionToken,
        cursor,
        onEvent,
        onState,
        onUnknownSession,
      ),
      onError: (_) {},
      cancelOnError: false,
    );
  }

  void _retry(
    int generation,
    String sessionToken,
    int Function() cursor,
    void Function(Map<String, Object?>) onEvent,
    void Function(KickRelayState) onState,
    void Function() onUnknownSession,
  ) {
    if (!this._running || generation != this._generation) return;
    this._attempts++;
    onState(KickRelayState.retrying);
    final seconds = (2 << (this._attempts.clamp(1, 6) - 1)).clamp(
      2,
      _maxBackoff.inSeconds,
    );
    this._sleep(Duration(seconds: seconds)).then((_) async {
      /// Repeated failures: ask plainly whether the session still exists
      /// (an upgrade rejection doesn't always carry its status code)
      if (this._attempts >= 2 &&
          this._running &&
          generation == this._generation &&
          await this._sessionUnknown(sessionToken)) {
        if (generation != this._generation) return;
        this._running = false;
        onState(KickRelayState.off);
        onUnknownSession();
        return;
      }
      this._open(
        generation,
        sessionToken,
        cursor,
        onEvent,
        onState,
        onUnknownSession,
      );
    });
  }

  Future<bool> _sessionUnknown(String sessionToken) async {
    try {
      final response = await this._client
          .get(
            Uri.parse('${this._baseUrl}/v1/events?after=0&limit=1'),
            headers: {'Authorization': 'Bearer $sessionToken'},
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 401;
    } catch (_) {
      return false;
    }
  }

  Future<void> stop() async {
    this._running = false;
    this._generation++;
    final sub = this._socketSub;
    final socket = this._socket;
    this._socketSub = null;
    this._socket = null;
    await sub?.cancel();
    try {
      await socket?.sink.close();
    } catch (_) {}
  }
}
