import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/models/connection.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/types/classes/connection_attempt_result.dart';
import 'package:obs_blade/types/enums/web_socket_codes/web_socket_close_code.dart';
import 'package:obs_blade/utils/remote/noise_ik.dart';
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
          connectPlan(
            hasRemote: hasRemote,
            isPro: isPro,
            onLocalNetwork: local,
          ),
          legs,
        );
      });
    }
  });

  test(
    'a host reachable from anywhere is still tried first on mobile data',
    () {
      expect(
        connectPlan(
          hasRemote: true,
          isPro: true,
          onLocalNetwork: false,
          hostIsLanOnly: false,
        ),
        [ConnectLeg.lan, ConnectLeg.remote],
      );
      for (final host in [
        '192.168.178.20',
        '10.0.0.5',
        '172.20.1.1',
        'obs.local',
        'localhost',
        '169.254.3.4',
        'fd12::1',
        'ws://192.168.1.2:4455',
      ]) {
        expect(hostIsLanOnly(host), isTrue, reason: host);
      }
      // own domain, public IP, Tailscale/CGNAT
      for (final host in [
        'obs.example.com',
        'wss://obs.example.com',
        '203.0.113.7',
        '100.101.102.103',
        '172.32.0.1',
      ]) {
        expect(hostIsLanOnly(host), isFalse, reason: host);
      }
    },
  );

  test('only a LAN that never answered moves on to the relay', () {
    ConnectionAttemptResult r(WebSocketCloseCode code, ConnectionStage stage) =>
        ConnectionAttemptResult(closeCode: code, stage: stage);
    expect(
      lanUnreachable(
        r(WebSocketCloseCode.HandshakeTimeout, ConnectionStage.connecting),
      ),
      isTrue,
    );
    expect(
      lanUnreachable(
        r(WebSocketCloseCode.UnknownReason, ConnectionStage.connecting),
      ),
      isTrue,
    );
    // OBS answered: its answer stands
    expect(
      lanUnreachable(
        r(
          WebSocketCloseCode.AuthenticationFailed,
          ConnectionStage.waitingIdentified,
        ),
      ),
      isFalse,
    );
    expect(
      lanUnreachable(
        r(WebSocketCloseCode.HandshakeTimeout, ConnectionStage.waitingHello),
      ),
      isFalse,
    );
    expect(lanUnreachable(null), isFalse);
  });

  test('relay close codes map to their own reasons with the PC name', () {
    for (var code = 4900; code <= 4911; code++) {
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

    Future<FakeRemoteEndpoint> relay(
      FakeEndpointMode mode, {
      int code = 4000,
    }) async {
      final endpoint = await FakeRemoteEndpoint.start(mode)
        ..closeCode = code;
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

    /// Paired with [bridge] (its key pinned, this phone's key known to
    /// it) - or with made-up keys when the relay refuses before any
    /// handshake.
    Future<Connection> paired(
      String host,
      int port, {
      FakeRemoteEndpoint? bridge,
      bool knownToBridge = true,
      List<int>? pinnedBridgeKey,
    }) async {
      final appKey = await NoiseKeyPair.generate();
      final bridgeKey =
          pinnedBridgeKey ??
          bridge?.bridgeKey.publicKey ??
          (await NoiseKeyPair.generate()).publicKey;
      if (bridge != null && knownToBridge) {
        bridge.pairedAppKeys.add(base64Encode(appKey.publicKey));
      }
      return Connection(host, port)
        ..relayBridgeId = 'b_1'
        ..relayAppToken = 'tok'
        ..relayDeviceId = 'd_1'
        ..relayBridgeName = 'GAMING-PC'
        ..relayBridgeKind = 'standalone'
        ..relayAppKey = base64Encode(appKey.privateKey)
        ..relayBridgeKey = base64Encode(bridgeKey);
    }

    test(
      'unreachable LAN on Wi-Fi falls back to the relay, one Connecting phase',
      () async {
        final endpoint = await relay(FakeEndpointMode.obs);
        final network = store(endpoint);
        final phases = <bool>[];
        final dispose = reaction(
          (_) => network.connectionInProgress,
          phases.add,
        );

        final code = await network.setOBSWebSocket(
          await paired('127.0.0.1', await closedPort(), bridge: endpoint),
        );

        dispose();
        expect(code, WebSocketCloseCode.DontClose);
        expect(network.activeSession!.viaRemote, isTrue);
        expect(phases, [true, false]); // no flash of the LAN failure
        // End to end: the bridge decrypted the Identify, nothing readable
        // crossed the relay
        expect(endpoint.received.map((m) => m['op']), contains(1));
        expect(endpoint.plainFrames, 0);
        /// The last attempt: under test-runner load a first one can time
        /// out and be retried (seen 2026-11-09)
        final upgrade = endpoint.upgrades.last;
        expect(upgrade.path, '/v1/app');
        expect(upgrade.query, {'bridge': 'b_1'});
        expect(upgrade.headers['authorization'], 'Bearer tok');
        expect(upgrade.headers['x-rc-app-user-id'], r'$RCAnonymousID:me');
        expect(upgrade.headers['sec-websocket-protocol'], 'obswebsocket.json');
        network.closeSession();
      },
    );

    test('reachable LAN wins; the relay is never asked', () async {
      final endpoint = await relay(FakeEndpointMode.obs);
      final peer = await FakeObsPeer.start();
      peers.add(peer);
      final network = store(endpoint);
      final lan = peer.connection;
      final connection = await paired(lan.host, lan.port!, bridge: endpoint);

      expect(
        await network.setOBSWebSocket(connection),
        WebSocketCloseCode.DontClose,
      );
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
        await network.setOBSWebSocket(
          await paired(
            peer.connection.host,
            peer.connection.port!,
            bridge: endpoint,
          ),
        ),
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

      final code = await network.setOBSWebSocket(
        await paired('127.0.0.1', await closedPort()),
      );

      expect(code, isNot(WebSocketCloseCode.DontClose));
      expect(endpoint.upgrades, isEmpty); // the relay is never asked
    });

    test(
      'paired but Pro lapsed: away from home it says Pro, not "check Wi-Fi"',
      () async {
        isPro = false;
        final endpoint = await relay(FakeEndpointMode.obs);
        final network = store(endpoint);

        final code = await network.setOBSWebSocket(
          await paired('127.0.0.1', await closedPort()),
        );

        expect(code, WebSocketCloseCode.RemoteProRequired);
        expect(
          network.lastConnectionResult!.userMessage,
          'Remote access is part of Pro.',
        );
        expect(endpoint.upgrades, isEmpty);
      },
    );

    test(
      'OBS refusing the password on the LAN is not retried over the relay',
      () async {
        final endpoint = await relay(FakeEndpointMode.obs);
        final lanObs = await relay(
          FakeEndpointMode.closeOnIdentify,
          code: 4009,
        );
        final network = store(endpoint);

        final code = await network.setOBSWebSocket(
          await paired('127.0.0.1', lanObs.port),
        );

        expect(code, WebSocketCloseCode.AuthenticationFailed);
        expect(endpoint.upgrades, isEmpty);
      },
    );

    test('relay refusals carry their reason and the PC name', () async {
      onLocalNetwork = false;
      final endpoint = await relay(FakeEndpointMode.closeAtOnce, code: 4901);
      final network = store(endpoint);

      final code = await network.setOBSWebSocket(
        await paired('127.0.0.1', 4455),
      );

      expect(code, WebSocketCloseCode.RemoteObsNotRunning);
      expect(network.lastConnectionResult!.viaRemote, isTrue);
      expect(
        network.lastConnectionResult!.userMessage,
        "OBS isn't running on GAMING-PC.",
      );
    });

    test('a revoked pairing is forgotten', () async {
      onLocalNetwork = false;
      final endpoint = await relay(FakeEndpointMode.closeAtOnce, code: 4904);
      final network = store(endpoint);
      final connection = await paired('127.0.0.1', 4455);

      expect(
        await network.setOBSWebSocket(connection),
        WebSocketCloseCode.RemoteUnpaired,
      );
      expect(connection.hasRemote, isFalse);
      expect(connection.relayBridgeName, isNull);
      expect(connection.relayAppKey, isNull);
    });

    test('a relay posing as the bridge is refused by the app itself', () async {
      onLocalNetwork = false;
      final endpoint = await relay(FakeEndpointMode.forgedHandshake);
      final network = store(endpoint);
      final connection = await paired('127.0.0.1', 4455, bridge: endpoint);

      final code = await network.setOBSWebSocket(connection);

      expect(code, WebSocketCloseCode.RemoteE2eFailed);
      expect(
        network.lastConnectionResult!.userMessage,
        "Couldn't verify GAMING-PC. Set up remote access again on your home Wi-Fi.",
      );
      expect(connection.hasRemote, isTrue, reason: 'not dropped on a forgery');
      expect(endpoint.received, isEmpty);
    });

    test(
      'a bridge with another key than pinned cannot open the session',
      () async {
        onLocalNetwork = false;
        final endpoint = await relay(FakeEndpointMode.obs);
        final network = store(endpoint);
        final other = await NoiseKeyPair.generate();

        final code = await network.setOBSWebSocket(
          await paired(
            '127.0.0.1',
            4455,
            bridge: endpoint,
            pinnedBridgeKey: other.publicKey,
          ),
        );

        expect(code, WebSocketCloseCode.RemoteE2eFailed);
        expect(endpoint.received, isEmpty);
      },
    );

    test("a phone the bridge doesn't know is forgotten (4904)", () async {
      onLocalNetwork = false;
      final endpoint = await relay(FakeEndpointMode.obs);
      final network = store(endpoint);
      final connection = await paired(
        '127.0.0.1',
        4455,
        bridge: endpoint,
        knownToBridge: false,
      );

      expect(
        await network.setOBSWebSocket(connection),
        WebSocketCloseCode.RemoteUnpaired,
      );
      expect(connection.hasRemote, isFalse);
    });

    test(
      'a pairing from before end-to-end encryption counts as unpaired',
      () async {
        final connection = (await paired('127.0.0.1', 4455))
          ..relayAppKey = null;
        expect(connection.hasRemote, isFalse);
      },
    );
  });
}
