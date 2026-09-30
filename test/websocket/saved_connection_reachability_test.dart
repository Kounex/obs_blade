import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/models/connection.dart';
import 'package:obs_blade/utils/network_helper.dart';

/// Reachability dot on the saved-connection cards
/// ([NetworkHelper.checkConnectionAvailabilities]) - domain-mode connections
/// store their scheme in the host (`ws://<IP>`) and are probed with a real
/// WebSocket upgrade instead of a plain TCP connect.
void main() {
  late HttpServer server;
  final openSockets = <WebSocket>[];

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

    /// Behaves like OBS for this purpose: accepts the upgrade, sends Hello
    /// and keeps the unidentified session open
    server.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      openSockets.add(socket);
      socket.add('{"op":0,"d":{"rpcVersion":1}}');
      socket.listen((_) {});
    });
  });

  tearDown(() async {
    for (final socket in openSockets) {
      await socket.close();
    }
    openSockets.clear();
    await server.close(force: true);
  });

  test('domain mode ws://<IP> with a listening server is reachable', () async {
    final connection = Connection(
      'ws://${InternetAddress.loopbackIPv4.address}',
      server.port,
      null,
      true,
    );

    final available = await NetworkHelper.checkConnectionAvailabilities([
      connection,
    ]);

    expect(available.map((c) => c.host), [connection.host]);
  });

  test('domain mode host without a server is not reachable', () async {
    /// Grab a free port and release it so nothing listens there
    final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final deadPort = probe.port;
    await probe.close();

    final available = await NetworkHelper.checkConnectionAvailabilities([
      Connection(
        'ws://${InternetAddress.loopbackIPv4.address}',
        deadPort,
        null,
        true,
      ),
    ]);

    expect(available, isEmpty);
  });

  test('plain IP with a listening server is reachable', () async {
    final available = await NetworkHelper.checkConnectionAvailabilities([
      Connection(InternetAddress.loopbackIPv4.address, server.port),
    ]);

    expect(available, hasLength(1));
  });
}
