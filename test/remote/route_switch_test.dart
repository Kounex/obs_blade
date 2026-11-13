import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/connection.dart';
import 'package:obs_blade/stores/pro_store.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/classes/session.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/types/enums/web_socket_codes/web_socket_close_code.dart';
import 'package:obs_blade/utils/pro_purchase_service.dart';
import 'package:obs_blade/utils/remote/noise_ik.dart';
import 'package:obs_blade/utils/remote/remote_connect.dart';
import 'package:obs_blade/utils/remote/remote_relay_client.dart';

import '../persistence/support/hive_test_harness.dart';
import '../pro/support/fake_pro_purchase_gateway.dart';
import '../websocket/support/fake_obs_peer.dart';
import 'support/fake_remote_endpoint.dart';

/// Mid-session route switches (dogfood 2026-11-08): Wi-Fi off on a LAN
/// session switched to the relay only once iOS reported the old socket
/// dead (ping timeout). Now the network change itself switches - and
/// Wi-Fi back moves a relay session to the LAN when OBS answers there.
void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeObsPeer lan;
  late FakeRemoteEndpoint relay;
  late NetworkStore network;
  late DashboardStore dashboard;
  late ProStore pro;
  late bool onLocalNetwork;

  Future<void> waitFor(bool Function() condition, String what) async {
    for (var i = 0; i < 500; i++) {
      if (condition()) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('Timed out waiting for: $what');
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('route_switch');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();
    await Hive.box(
      HiveKeys.Settings.name,
    ).put(SettingsKeys.BoughtPro.name, true);
    await Hive.box(
      HiveKeys.Settings.name,
    ).put(SettingsKeys.ProColdStartRestoreDone.name, true);
    pro = ProStore(
      service: ProPurchaseService(gateway: FakeProPurchaseGateway()),
    )..init();

    lan = await FakeObsPeer.start();
    lan.responseData['GetVersion'] = {
      'availableRequests': <String>[],
      'supportedImageFormats': ['jpg', 'png'],
    };
    relay = await FakeRemoteEndpoint.start(FakeEndpointMode.obs);
    onLocalNetwork = true;

    network = NetworkStore(
      remote: RemoteConnectEnvironment(
        isPro: () => pro.isPro,
        onLocalNetwork: () async => onLocalNetwork,
        appUserId: () async => 'me',
        relay: RemoteRelayClient(baseUrl: relay.baseUrl),
      ),
    );
    dashboard = DashboardStore();
    GetIt.instance
      ..registerSingleton<ProStore>(pro)
      ..registerSingleton<NetworkStore>(network)
      ..registerSingleton<DashboardStore>(dashboard);
  });

  tearDown(() async {
    /// The reconnect's 3 s check timer would act on the next test's stores
    dashboard.stopTimers();
    dashboard.disposeListeners();
    network.closeSession();
    await lan.close();
    await relay.close();
    pro.dispose();
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<Connection> paired() async {
    final appKey = await NoiseKeyPair.generate();
    relay.pairedAppKeys.add(base64Encode(appKey.publicKey));
    return lan.connection
      ..relayBridgeId = 'b_1'
      ..relayAppToken = 'tok'
      ..relayDeviceId = 'd_1'
      ..relayBridgeName = 'GAMING-PC'
      ..relayBridgeKind = 'standalone'
      ..relayAppKey = base64Encode(appKey.privateKey)
      ..relayBridgeKey = base64Encode(relay.bridgeKey.publicKey);
  }

  Future<void> connectOnLan(Connection connection) async {
    expect(
      await network.setOBSWebSocket(connection),
      WebSocketCloseCode.DontClose,
    );
    expect(network.activeSession!.viaRemote, isFalse);
    dashboard.handleStream();
  }

  test('Wi-Fi off: straight to the relay, the LAN socket closed', () async {
    await connectOnLan(await paired());

    onLocalNetwork = false;
    await dashboard.onNetworkChanged([ConnectivityResult.mobile]);

    expect(network.activeSession!.viaRemote, isTrue);
    expect(dashboard.routeSwitch, RouteSwitch.toRelay);
    expect(dashboard.reconnecting, isFalse);
    await waitFor(
      () => lan.sockets.isEmpty,
      'LAN socket closed (OBS saw it end)',
    );
    expect(
      relay.received.map((m) => m['op']),
      contains(1),
      reason: 'identified, encrypted',
    );
  });

  test(
    'Wi-Fi back: to the LAN when OBS answers there, the relay closed',
    () async {
      final Connection connection = await paired();
      onLocalNetwork = false;
      expect(
        await network.setOBSWebSocket(connection),
        WebSocketCloseCode.DontClose,
      );
      final Session relaySession = network.activeSession!;
      expect(relaySession.viaRemote, isTrue);
      dashboard.handleStream();

      onLocalNetwork = true;
      await dashboard.onNetworkChanged([ConnectivityResult.wifi]);

      expect(network.activeSession!.viaRemote, isFalse);
      expect(dashboard.routeSwitch, RouteSwitch.toLan);
      await waitFor(
        () => relay.sockets.single.closeCode != null,
        'relay session closed (the relay saw the close)',
      );
    },
  );

  test(
    'Wi-Fi back, OBS not answering on the LAN: the relay session stays',
    () async {
      final Connection connection = await paired();
      onLocalNetwork = false;
      expect(
        await network.setOBSWebSocket(connection),
        WebSocketCloseCode.DontClose,
      );
      final Session relaySession = network.activeSession!;
      dashboard.handleStream();
      await lan.close();

      onLocalNetwork = true;
      await dashboard.onNetworkChanged([ConnectivityResult.wifi]);

      expect(identical(network.activeSession, relaySession), isTrue);
      expect(dashboard.reconnecting, isFalse);
      expect(dashboard.routeSwitch, isNull);
    },
  );

  test('Wi-Fi back, OBS on the LAN refuses the session (wrong saved password): '
      'one try, the relay session stays and keeps working', () async {
    /// Unlimited Reconnects used to keep the forced switch retrying
    /// forever; then the working relay session was closed
    await Hive.box(
      HiveKeys.Settings.name,
    ).put(SettingsKeys.UnlimitedReconnects.name, true);
    final Connection connection = await paired();
    onLocalNetwork = false;
    expect(
      await network.setOBSWebSocket(connection),
      WebSocketCloseCode.DontClose,
    );
    final Session relaySession = network.activeSession!;
    dashboard.handleStream();
    lan.identify = false;

    onLocalNetwork = true;
    await dashboard.onNetworkChanged([ConnectivityResult.wifi]);

    expect(identical(network.activeSession, relaySession), isTrue);
    expect(relaySession.socket.closeCode, isNull);
    expect(dashboard.reconnecting, isFalse);
    expect(dashboard.routeSwitch, isNull);
    expect(network.obsTerminated, isFalse);
  });

  test('not paired, or no Pro: a network change switches nothing', () async {
    await connectOnLan(lan.connection);
    final Session before = network.activeSession!;
    await dashboard.onNetworkChanged([ConnectivityResult.mobile]);
    expect(identical(network.activeSession, before), isTrue);

    network.closeSession();
    await connectOnLan(await paired());
    final Session pairedSession = network.activeSession!;
    await Hive.box(
      HiveKeys.Settings.name,
    ).put(SettingsKeys.BoughtPro.name, false);
    await waitFor(() => !pro.isPro, 'Pro gone');
    await dashboard.onNetworkChanged([ConnectivityResult.mobile]);
    expect(identical(network.activeSession, pairedSession), isTrue);
    expect(
      relay.upgrades,
      isEmpty,
      reason: relay.upgrades.map((u) => '${u.path} ${u.query}').join(', '),
    );
  });
}
