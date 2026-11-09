import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:obs_blade/utils/remote/noise_ik.dart';

/// What the endpoint does with a websocket after the upgrade.
enum FakeEndpointMode {
  /// Behaves like the bridge + OBS behind the relay, as
  /// `desktop/core/src/session.rs` does: the end-to-end handshake (an
  /// app key not in [FakeRemoteEndpoint.pairedAppKeys] -> close 4904, a
  /// message 1 that doesn't decrypt -> 4911), then Hello without
  /// `authentication` and Identified on Identify - all encrypted.
  obs,

  /// Answers message 1 with garbage: what a relay pretending to be the
  /// bridge could do (the app must refuse it itself).
  forgedHandshake,

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
  FakeRemoteEndpoint._(this._server, this.mode, this.bridgeKey) {
    _server.listen((request) async {
      upgrades.add(
        FakeUpgrade(
          path: request.uri.path,
          query: request.uri.queryParameters,
          headers: {
            for (final name in [
              'authorization',
              'x-rc-app-user-id',
              'sec-websocket-protocol',
            ])
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
              protocols.contains('obswebsocket.json')
              ? 'obswebsocket.json'
              : null,
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
        case FakeEndpointMode.forgedHandshake:
          _bridge(socket);
          return;
        case FakeEndpointMode.closeOnIdentify:
          socket.add(
            jsonEncode({
              'op': 0,
              'd': {
                'obsWebSocketVersion': '5.7.6',
                'rpcVersion': 1,
                'authentication': {'challenge': 'c', 'salt': 's'},
              },
            }),
          );
      }
      socket.listen((raw) async {
        final message = jsonDecode(raw as String) as Map<String, dynamic>;
        if (message['op'] != 1) return;
        if (this.mode == FakeEndpointMode.closeOnIdentify) {
          await socket.close(this.closeCode, 'Authentication failed.');
          return;
        }
        socket.add(
          jsonEncode({
            'op': 2,
            'd': {'negotiatedRpcVersion': 1},
          }),
        );
      });
    });
  }

  /// The bridge's session: handshake, then sealed obs-websocket
  void _bridge(WebSocket socket) {
    NoiseTransport? transport;
    Future<void> chain = Future.value();
    void send(Map<String, dynamic> message) {
      for (final frame in transport!.seal(utf8.encode(jsonEncode(message)))) {
        socket.add(frame);
      }
    }

    socket.listen((raw) {
      chain = chain.then((_) async {
        if (raw is! List<int>) {
          plainFrames++;
          await socket.close(1003, 'end-to-end encryption required');
          return;
        }
        if (transport == null) {
          if (this.mode == FakeEndpointMode.forgedHandshake) {
            socket.add(Uint8List(48));
            return;
          }
          final responder = NoiseIKResponder(localStatic: this.bridgeKey);
          try {
            await responder.readMessage1(raw);
          } on NoiseException {
            await socket.close(4911, 'handshake failed');
            return;
          }
          final appKey = base64Encode(responder.remoteStatic!);
          if (!this.pairedAppKeys.contains(appKey)) {
            await socket.close(4904, "this device isn't paired");
            return;
          }
          final (message2, established) = await responder.writeMessage2();
          transport = established;
          socket.add(message2);
          send({
            'op': 0,
            'd': {'obsWebSocketVersion': '5.7.6', 'rpcVersion': 1},
          });
          return;
        }
        final plain = transport!.open(raw);
        if (plain == null) return;
        final message = jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
        received.add(message);
        if (message['op'] == 1) {
          send({
            'op': 2,
            'd': {'negotiatedRpcVersion': 1},
          });
        }

        /// Requests: answered (an empty success), like OBS through the
        /// bridge - the app's liveness counts these
        if (message['op'] == 6) {
          final d = message['d'] as Map<String, dynamic>;
          send({
            'op': 7,
            'd': {
              'requestType': d['requestType'],
              'requestId': d['requestId'],
              'requestStatus': {'result': true, 'code': 100},
              'responseData': <String, dynamic>{},
            },
          });
        }
      });
    });
  }

  final HttpServer _server;
  final FakeEndpointMode mode;

  /// The bridge's static key; the app pins its public half when paired
  final NoiseKeyPair bridgeKey;

  /// base64 public keys of the paired phones
  final Set<String> pairedAppKeys = {};

  /// Decrypted messages from the app (bridge modes)
  final List<Map<String, dynamic>> received = [];

  /// Readable frames that reached the bridge (must stay 0)
  int plainFrames = 0;
  final List<WebSocket> _sockets = [];

  /// The server side of every upgraded socket
  List<WebSocket> get sockets => List.unmodifiable(_sockets);
  final List<FakeUpgrade> upgrades = [];
  int closeCode = 4000;

  int get port => _server.port;
  String get baseUrl => 'http://127.0.0.1:${_server.port}';

  static Future<FakeRemoteEndpoint> start(FakeEndpointMode mode) async =>
      FakeRemoteEndpoint._(
        await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
        mode,
        await NoiseKeyPair.generate(),
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

  const FakeUpgrade({
    required this.path,
    required this.query,
    required this.headers,
  });
}

/// A loopback port nothing listens on (bound once, then released) - an
/// unreachable LAN OBS that refuses at once.
Future<int> closedPort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}
