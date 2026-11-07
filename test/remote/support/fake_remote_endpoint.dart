import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// What the endpoint does with a websocket after the upgrade.
enum FakeEndpointMode {
  /// Behaves like OBS behind the relay: Hello without `authentication`,
  /// Identified on Identify.
  obs,

  /// Closes right after the upgrade with [FakeRemoteEndpoint.closeCode] -
  /// how the relay refuses (tool/remote_relay/relay.py `refuse`).
  closeAtOnce,

  /// Sends Hello (with an auth challenge), then closes with
  /// [FakeRemoteEndpoint.closeCode] on Identify - OBS refusing a password.
  closeOnIdentify,
}

/// Loopback websocket endpoint that records each upgrade's headers and
/// query - stands in for the remote relay's `/v1/app` (and, in
/// [FakeEndpointMode.closeOnIdentify], for a LAN OBS with a password).
class FakeRemoteEndpoint {
  FakeRemoteEndpoint._(this._server, this.mode) {
    _server.listen((request) async {
      upgrades.add(
        FakeUpgrade(
          path: request.uri.path,
          query: request.uri.queryParameters,
          headers: {
            for (final name in ['authorization', 'x-rc-app-user-id', 'sec-websocket-protocol'])
              if (request.headers.value(name) != null)
                name: request.headers.value(name)!,
          },
        ),
      );
      final WebSocket socket;
      try {
        socket = await WebSocketTransformer.upgrade(
          request,
          protocolSelector: (protocols) =>
              protocols.contains('obswebsocket.json') ? 'obswebsocket.json' : null,
        );
      } catch (_) {
        return;
      }
      _sockets.add(socket);
      switch (this.mode) {
        case FakeEndpointMode.closeAtOnce:
          await socket.close(this.closeCode, 'refused');
          return;
        case FakeEndpointMode.obs:
          socket.add(jsonEncode({
            'op': 0,
            'd': {'obsWebSocketVersion': '5.7.6', 'rpcVersion': 1},
          }));
        case FakeEndpointMode.closeOnIdentify:
          socket.add(jsonEncode({
            'op': 0,
            'd': {
              'obsWebSocketVersion': '5.7.6',
              'rpcVersion': 1,
              'authentication': {'challenge': 'c', 'salt': 's'},
            },
          }));
      }
      socket.listen((raw) async {
        final message = jsonDecode(raw as String) as Map<String, dynamic>;
        if (message['op'] != 1) return;
        if (this.mode == FakeEndpointMode.closeOnIdentify) {
          await socket.close(this.closeCode, 'Authentication failed.');
          return;
        }
        socket.add(jsonEncode({'op': 2, 'd': {'negotiatedRpcVersion': 1}}));
      });
    });
  }

  final HttpServer _server;
  final FakeEndpointMode mode;
  final List<WebSocket> _sockets = [];
  final List<FakeUpgrade> upgrades = [];
  int closeCode = 4000;

  int get port => _server.port;
  String get baseUrl => 'http://127.0.0.1:${_server.port}';

  static Future<FakeRemoteEndpoint> start(FakeEndpointMode mode) async =>
      FakeRemoteEndpoint._(
        await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
        mode,
      );

  Future<void> close() async {
    for (final socket in List.of(_sockets)) {
      await socket.close();
    }
    await _server.close(force: true);
  }
}

class FakeUpgrade {
  final String path;
  final Map<String, String> query;
  final Map<String, String> headers;

  const FakeUpgrade({required this.path, required this.query, required this.headers});
}

/// A loopback port nothing listens on (bound once, then released) - an
/// unreachable LAN OBS that refuses at once.
Future<int> closedPort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}
