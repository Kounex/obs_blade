import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/models/connection.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/types/classes/connection_attempt_result.dart';
import 'package:obs_blade/types/enums/web_socket_codes/web_socket_close_code.dart';
import 'package:obs_blade/utils/remote/remote_connect.dart';
import 'package:obs_blade/utils/remote/remote_relay_client.dart';

import '../persistence/support/hive_test_harness.dart';
import '../websocket/support/fake_obs_peer.dart';
import 'support/fake_remote_endpoint.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('connectPlan', () {
    for (final (hasRemote, isPro, local, legs) in [
      (false, true, true, [ConnectLeg.lan]),
      (false, true, false, [ConnectLeg.lan]),
      (true, false, true, [ConnectLeg.lan]),
      (true, false, false, [ConnectLeg.lan]),
      (true, true, false, [ConnectLeg.remote]),
      (true, true, true, [ConnectLeg.lan, ConnectLeg.remote]),
    ]) {
      test('paired=$hasRemote pro=$isPro localNetwork=$local -> $legs', () {
        expect(
          connectPlan(hasRemote: hasRemote, isPro: isPro, onLocalNetwork: local),
          legs,
        );
      });
    }
  });

  test('only a LAN that never answered moves on to the relay', () {
    ConnectionAttemptResult r(WebSocketCloseCode code, ConnectionStage stage) =>
        ConnectionAttemptResult(closeCode: code, stage: stage);
    expect(lanUnreachable(r(WebSocketCloseCode.HandshakeTimeout, ConnectionStage.connecting)), isTrue);
    expect(lanUnreachable(r(WebSocketCloseCode.UnknownReason, ConnectionStage.connecting)), isTrue);
    // OBS answered: its answer stands
    expect(lanUnreachable(r(WebSocketCloseCode.AuthenticationFailed, ConnectionStage.waitingIdentified)), isFalse);
    expect(lanUnreachable(r(WebSocketCloseCode.HandshakeTimeout, ConnectionStage.waitingHello)), isFalse);
    expect(lanUnreachable(null), isFalse);
  });

  test('relay close codes map to their own reasons with the PC name', () {
    for (var code = 4900; code <= 4910; code++) {
      final value = WebSocketCloseCode.fromIdentifier(code);
      expect(value.isRemote, isTrue, reason: '$code');
      expect(value, isNot(WebSocketCloseCode.UnknownReason), reason: '$code');
    }
    final result = const ConnectionAttemptResult(
      closeCode: WebSocketCloseCode.RemoteObsNotRunning,
      stage: ConnectionStage.connecting,
    ).withRemote('GAMING-PC');
    expect(result.userMessage, "OBS isn't running on GAMING-PC.");
    expect(
      const ConnectionAttemptResult(
        closeCode: WebSocketCloseCode.HandshakeTimeout,
        stage: ConnectionStage.connecting,
        viaRemote: true,
      ).userMessage,
      contains('remote relay'),
    );
  });

  group('NetworkStore routes', () {
    late Directory tempDir;
    late HiveTestHarness harness;
    late List<FakeRemoteEndpoint> endpoints;
    late List<FakeObsPeer> peers;
    late bool isPro;
    late bool onLocalNetwork;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('remote_connect');
      harness = HiveTestHarness(tempDir);
      await harness.init();
      await harness.openAllBoxes();
      endpoints = [];
      peers = [];
      isPro = true;
      onLocalNetwork = true;
    });

    tearDown(() async {
      for (final e in endpoints) {
        await e.close();
      }
      for (final p in peers) {
        await p.close();
      }
      await harness.close();
      await tempDir.delete(recursive: true);
    });

    Future<FakeRemoteEndpoint> relay(FakeEndpointMode mode, {int code = 4000}) async {
      final endpoint = await FakeRemoteEndpoint.start(mode)..closeCode = code;
      endpoints.add(endpoint);
      return endpoint;
    }

    NetworkStore store(FakeRemoteEndpoint relayEndpoint) => NetworkStore(
      remote: RemoteConnectEnvironment(
        isPro: () => isPro,
        onLocalNetwork: () async => onLocalNetwork,
        appUserId: () async => r'$RCAnonymousID:me',
        relay: RemoteRelayClient(baseUrl: relayEndpoint.baseUrl),
      ),
    );

    Connection paired(String host, int port) => Connection(host, port)
      ..relayBridgeId = 'b_1'
      ..relayAppToken = 'tok'
      ..relayDeviceId = 'd_1'
      ..relayBridgeName = 'GAMING-PC'
      ..relayBridgeKind = 'standalone';

    test('unreachable LAN on Wi-Fi falls back to the relay, one Connecting phase', () async {
      final endpoint = await relay(FakeEndpointMode.obs);
      final network = store(endpoint);
      final phases = <bool>[];
      final dispose = reaction((_) => network.connectionInProgress, phases.add);

      final code = await network.setOBSWebSocket(paired('127.0.0.1', await closedPort()));

      dispose();
      expect(code, WebSocketCloseCode.DontClose);
      expect(network.activeSession!.viaRemote, isTrue);
      expect(phases, [true, false]); // no flash of the LAN failure
      final upgrade = endpoint.upgrades.single;
      expect(upgrade.path, '/v1/app');
      expect(upgrade.query, {'bridge': 'b_1'});
      expect(upgrade.headers['authorization'], 'Bearer tok');
      expect(upgrade.headers['x-rc-app-user-id'], r'$RCAnonymousID:me');
      expect(upgrade.headers['sec-websocket-protocol'], 'obswebsocket.json');
      network.closeSession();
    });

    test('reachable LAN wins; the relay is never asked', () async {
      final endpoint = await relay(FakeEndpointMode.obs);
      final peer = await FakeObsPeer.start();
      peers.add(peer);
      final network = store(endpoint);
      final lan = peer.connection;
      final connection = paired(lan.host, lan.port!);

      expect(await network.setOBSWebSocket(connection), WebSocketCloseCode.DontClose);
      expect(network.activeSession!.viaRemote, isFalse);
      expect(endpoint.upgrades, isEmpty);
      network.closeSession();
    });

    test('on mobile data the relay is used straight away', () async {
      onLocalNetwork = false;
      final endpoint = await relay(FakeEndpointMode.obs);
      final peer = await FakeObsPeer.start();
      peers.add(peer);
      final network = store(endpoint);

      expect(
        await network.setOBSWebSocket(paired(peer.connection.host, peer.connection.port!)),
        WebSocketCloseCode.DontClose,
      );
      expect(network.activeSession!.viaRemote, isTrue);
      expect(peer.sockets, isEmpty);
      network.closeSession();
    });

    test('without Pro a paired connection stays on the LAN', () async {
      isPro = false;
      final endpoint = await relay(FakeEndpointMode.obs);
      final network = store(endpoint);

      final code = await network.setOBSWebSocket(paired('127.0.0.1', await closedPort()));

      expect(code, isNot(WebSocketCloseCode.DontClose));
      expect(network.lastConnectionResult!.viaRemote, isFalse);
      expect(endpoint.upgrades, isEmpty);
    });

    test('OBS refusing the password on the LAN is not retried over the relay', () async {
      final endpoint = await relay(FakeEndpointMode.obs);
      final lanObs = await relay(FakeEndpointMode.closeOnIdentify, code: 4009);
      final network = store(endpoint);

      final code = await network.setOBSWebSocket(paired('127.0.0.1', lanObs.port));

      expect(code, WebSocketCloseCode.AuthenticationFailed);
      expect(endpoint.upgrades, isEmpty);
    });

    test('relay refusals carry their reason and the PC name', () async {
      onLocalNetwork = false;
      final endpoint = await relay(FakeEndpointMode.closeAtOnce, code: 4901);
      final network = store(endpoint);

      final code = await network.setOBSWebSocket(paired('127.0.0.1', 4455));

      expect(code, WebSocketCloseCode.RemoteObsNotRunning);
      expect(network.lastConnectionResult!.viaRemote, isTrue);
      expect(network.lastConnectionResult!.userMessage, "OBS isn't running on GAMING-PC.");
    });

    test('a revoked pairing is forgotten', () async {
      onLocalNetwork = false;
      final endpoint = await relay(FakeEndpointMode.closeAtOnce, code: 4904);
      final network = store(endpoint);
      final connection = paired('127.0.0.1', 4455);

      expect(await network.setOBSWebSocket(connection), WebSocketCloseCode.RemoteUnpaired);
      expect(connection.hasRemote, isFalse);
      expect(connection.relayBridgeName, isNull);
    });
  });
}
