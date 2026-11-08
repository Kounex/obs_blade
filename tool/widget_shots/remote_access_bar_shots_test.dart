import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/models/connection.dart';
import 'package:obs_blade/stores/pro_store.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/classes/session.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/remote_reach.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/pro_purchase_service.dart';
import 'package:obs_blade/views/dashboard/widgets/status_app_bar/status_app_bar.dart';
import 'package:obs_blade/views/home/widgets/saved_connections/connection_box.dart';
import 'package:web_socket_channel/io.dart';

import '../../test/pro/support/fake_pro_purchase_gateway.dart';
import 'support/shots_harness.dart';

/// Remote access entry points (2026-11-08): the globe in the dashboard bar
/// (not set up / set up / through the relay) and the saved card's line
/// with what the relay says about the PC.
void main() {
  final harness = ShotsHarness();
  late HttpServer server;
  late IOWebSocketChannel socket;
  late ProStore proStore;

  setUpAll(ShotsHarness.loadFonts);

  Future<void> setUpStores(WidgetTester tester, {bool pro = true}) async {
    await tester.runAsync(() async {
      final box = Hive.box(HiveKeys.Settings.name);
      await box.put(SettingsKeys.BoughtPro.name, pro);
      await box.put(SettingsKeys.ProColdStartRestoreDone.name, true);
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          await WebSocketTransformer.upgrade(request);
        } else {
          request.response.statusCode = 404;
          await request.response.close();
        }
      });
      socket = IOWebSocketChannel.connect('ws://127.0.0.1:${server.port}');
      await socket.ready;
    });
    proStore = ProStore(
      service: ProPurchaseService(gateway: FakeProPurchaseGateway()),
    )..init();
    GetIt.instance
      ..registerSingleton<ProStore>(proStore)
      ..registerSingleton<NetworkStore>(NetworkStore())
      ..registerSingleton<DashboardStore>(DashboardStore());
  }

  setUp(harness.setUp);

  tearDown(() async {
    await socket.sink.close();
    await server.close(force: true);
    proStore.dispose();
    await GetIt.instance.reset();
    await harness.tearDown();
  });

  Connection connection({bool paired = false}) {
    final c = Connection('192.168.178.20', 4455)
      ..name = 'GAMING-PC'
      ..pw = 'secret'
      ..lastConnectedMs =
          DateTime.now().millisecondsSinceEpoch - 2 * 3600 * 1000;
    if (paired) {
      c
        ..relayBridgeId = 'b_1'
        ..relayAppToken = 'tok'
        ..relayDeviceId = 'd_me'
        ..relayBridgeName = 'GAMING-PC'
        ..relayBridgeKind = 'standalone';
    }
    return c;
  }

  Widget bar() => const CustomScrollView(
    slivers: [
      StatusAppBar(),
      SliverToBoxAdapter(child: SizedBox(height: 400)),
    ],
  );

  for (final (name, pro, paired, viaRemote) in [
    ('remote_bar_free', false, false, false),
    ('remote_bar_not_set_up', true, false, false),
    ('remote_bar_set_up', true, true, false),
    ('remote_bar_via_relay', true, true, true),
  ]) {
    testWidgets(name, (tester) async {
      await setUpStores(tester, pro: pro);
      runInAction(
        () => GetIt.instance<NetworkStore>().activeSession = Session(
          socket,
          connection(paired: paired),
          viaRemote: viaRemote,
        ),
      );
      await harness.shot(tester, name, bar());
      if (name == 'remote_bar_via_relay') {
        await harness.shot(
          tester,
          '${name}_narrow',
          bar(),
          size: const Size(320, 640),
        );
      }
    });
  }

  testWidgets('saved card: what the relay says', (tester) async {
    await setUpStores(tester);
    for (final (name, reachable, reach) in [
      ('remote_card_relay_online', true, RemoteReach.obsRunning),
      ('remote_card_obs_not_running', false, RemoteReach.obsNotRunning),
      ('remote_card_pc_offline', false, RemoteReach.pcOffline),
      ('remote_card_relay_unknown', false, null),
    ]) {
      final Widget card = Center(
        child: ConnectionBox(
          connection: connection(paired: true)
            ..reachable = reachable
            ..remoteReach = reach,
        ),
      );
      await harness.shot(tester, name, card);
      if (reach == RemoteReach.obsUnreachable ||
          reach == RemoteReach.pcOffline) {
        await harness.shot(
          tester,
          '${name}_narrow',
          card,
          size: const Size(320, 640),
        );
      }
    }
  });
}
