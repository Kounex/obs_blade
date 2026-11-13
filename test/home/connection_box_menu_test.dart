import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/app.dart';
import 'package:obs_blade/models/connection.dart';
import 'package:obs_blade/stores/pro_store.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/remote_reach.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/pro_purchase_service.dart';
import 'package:obs_blade/shared/general/base/button.dart';
import 'package:obs_blade/views/home/widgets/saved_connections/connection_box.dart';

import '../persistence/support/hive_test_harness.dart';
import '../pro/support/fake_pro_purchase_gateway.dart';

/// The card's "..." opens the edit dialog straight away - it has Delete
/// itself, the Edit / Delete sheet in between is gone (2026-11-08).
void main() {
  late Directory tempDir;
  late HiveTestHarness harness;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('connection_box_menu');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();
    GetIt.instance.registerSingleton<NetworkStore>(NetworkStore());
    // Pro for the remote-access case (real Hive I/O stays out of the
    // testWidgets fake-async zone)
    final Box settings = Hive.box(HiveKeys.Settings.name);
    await settings.put(SettingsKeys.BoughtPro.name, true);
    await settings.put(SettingsKeys.ProColdStartRestoreDone.name, true);
    GetIt.instance.registerSingleton<ProStore>(
      ProStore(service: ProPurchaseService(gateway: FakeProPurchaseGateway()))
        ..init(),
    );
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('"..." opens Edit Connection with Delete in it', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: App.buildTheme(Hive.box(HiveKeys.Settings.name)),
        home: Scaffold(
          body: Center(
            child: ConnectionBox(
              connection: Connection('192.168.178.20', 4455)
                ..name = 'GAMING-PC'
                ..reachable = true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
    await tester.pumpAndSettle();

    expect(find.text('Edit Connection'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Edit'), findsNothing, reason: 'no action sheet');
  });

  /// Review 2026-11-13: a phone paired while the plugin was the PC side
  /// keeps relayBridgeKind 'plugin' after the user adds the app (same
  /// bridge). The relay saying OBS is closed on an online PC means the app
  /// answers - Connect stays the prominent way to start OBS
  testWidgets('OBS closed on an online PC paired as plugin: Connect is '
      'prominent', (tester) async {
    final settings = Hive.box(HiveKeys.Settings.name);
    await tester.pumpWidget(
      MaterialApp(
        theme: App.buildTheme(settings),
        home: Scaffold(
          body: Center(
            child: ConnectionBox(
              connection: Connection('192.168.178.20', 4455)
                ..name = 'GAMING-PC'
                ..relayBridgeId = 'b_1'
                ..relayAppToken = 'tok'
                ..relayDeviceId = 'd_me'
                ..relayAppKey = 'app-key'
                ..relayBridgeKey = 'bridge-key'
                ..relayBridgeName = 'GAMING-PC'
                ..relayBridgeKind = 'plugin'
                ..reachable = false
                ..remoteReach = RemoteReach.obsNotRunning,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('OBS closed'), findsOneWidget);
    final BaseButton connect = tester.widget(
      find.ancestor(
        of: find.text('Connect'),
        matching: find.byType(BaseButton),
      ),
    );
    expect(connect.secondary, isFalse, reason: 'filled, not the ghost');
  });
}
