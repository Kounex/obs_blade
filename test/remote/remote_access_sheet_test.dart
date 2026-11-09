import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/app.dart';
import 'package:obs_blade/models/connection.dart';
import 'package:obs_blade/stores/pro_store.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/remote_access.dart';
import 'package:obs_blade/types/classes/session.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/pro_purchase_service.dart';
import 'package:obs_blade/utils/remote/remote_relay_client.dart';
import 'package:obs_blade/views/dashboard/widgets/status_app_bar/general_actions.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../persistence/support/hive_test_harness.dart';
import '../pro/support/fake_pro_purchase_gateway.dart';

/// The session's socket is never used by the sheet
class _UnusedSocket implements WebSocketChannel {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Bridge info like tool/remote_relay/relay.py answers it
http.Client _relay({List<String>? renames}) => MockClient((request) async {
  if (request.method == 'PATCH' && request.url.path == '/v1/devices/d_me') {
    renames?.add(jsonDecode(request.body)['name'] as String);
    return http.Response('', 204);
  }
  if (request.url.path.startsWith('/v1/bridges/')) {
    return http.Response(
      jsonEncode({
        'id': 'b_1',
        'name': 'GAMING-PC',
        'kind': 'plugin',
        'version': '0.2.0',
        'online': true,
        'last_seen': 1794000000,
        'obs': 'running',
        'update_required': false,
        'devices': [
          {
            'id': 'd_me',
            'name': 'iPhone',
            'platform': 'ios',
            'last_used': 1794000000,
            'connected': true,
            'self': true,
          },
          {
            'id': 'd_ipad',
            'name': 'iPad Pro 11-Inch (M5)',
            'platform': 'ios',
            'last_used': 1793000000,
            'connected': false,
            'self': false,
          },
        ],
      }),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
  return http.Response('', 404);
});

/// The sheet has looping animations (status dot) - pumpAndSettle never ends
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late int storesCreated;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('remote_access_sheet');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();

    final Box settings = Hive.box(HiveKeys.Settings.name);
    await settings.put(SettingsKeys.BoughtPro.name, true);
    await settings.put(SettingsKeys.ProColdStartRestoreDone.name, true);
    GetIt.instance.registerSingleton<ProStore>(
      ProStore(service: ProPurchaseService(gateway: FakeProPurchaseGateway()))
        ..init(),
    );

    final Connection connection = Connection('192.168.1.20', 4455)
      ..name = 'Studio'
      ..relayBridgeId = 'b_1'
      ..relayAppToken = 'tok'
      ..relayDeviceId = 'd_me'
      ..relayAppKey = 'app-key'
      ..relayBridgeKey = 'bridge-key'
      /// As the relay answers it - a different name makes the store save
      /// the connection, a Hive write that never finishes in fake async
      ..relayBridgeName = 'GAMING-PC'
      ..relayBridgeKind = 'plugin';
    await Hive.box<Connection>(HiveKeys.SavedConnections.name).add(connection);
    GetIt.instance.registerSingleton<NetworkStore>(
      NetworkStore()..activeSession = Session(_UnusedSocket(), connection),
    );

    storesCreated = 0;
    GeneralActions.createRemoteAccessStore = () {
      storesCreated++;
      return RemoteAccessStore(relay: RemoteRelayClient(client: _relay()));
    };
  });

  tearDown(() async {
    GeneralActions.createRemoteAccessStore = RemoteAccessStore.new;
    await GetIt.instance.reset();
    await harness.close();
    await tempDir.delete(recursive: true);
  });

  /// Dogfood 2026-11-09: the store was created inside the sheet builder,
  /// which re-runs when a drag starts / ends - the sheet then showed a
  /// fresh, never-refreshed store: "Checking" forever
  testWidgets('a paired bridge stays Online while the sheet is dragged', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: App.buildTheme(Hive.box(HiveKeys.Settings.name)),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => GeneralActions.openRemoteAccess(context),
              child: const Text('globe'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('globe'));
    await _settle(tester);
    expect(find.text('Online'), findsOneWidget);

    /// A drag that doesn't close it: starts, moves a bit, lets go
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Remote Access')),
    );
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    await gesture.up();
    await _settle(tester);

    expect(find.text('Remote Access'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.text('Checking'), findsNothing);
    expect(storesCreated, 1);
  });

  /// Dogfood 2026-11-09: two phones both listed as "iPhone" on the PC
  testWidgets('this device: Rename (sent to the relay); others: Remove', (
    tester,
  ) async {
    final List<String> renames = [];
    GeneralActions.createRemoteAccessStore = () => RemoteAccessStore(
      relay: RemoteRelayClient(client: _relay(renames: renames)),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: App.buildTheme(Hive.box(HiveKeys.Settings.name)),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => GeneralActions.openRemoteAccess(context),
              child: const Text('globe'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('globe'));
    await _settle(tester);
    /// The route, LAN session to an online PC (dogfood 2026-11-09: only
    /// the relay had a line)
    expect(find.text('Connected on your network'), findsOneWidget);
    expect(find.text('Relay on standby'), findsOneWidget);
    expect(find.text('iPhone (this device)'), findsOneWidget);
    expect(find.text('Rename'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget, reason: 'the iPad only');

    await tester.tap(find.text('Rename'));
    await _settle(tester);
    expect(find.text('Rename Device'), findsOneWidget);
    await tester.enterText(find.byType(EditableText).last, '  Work iPhone ');
    await tester.tap(find.text('Save'));
    await _settle(tester);
    expect(renames, ['Work iPhone']);
    expect(find.text('Rename Device'), findsNothing);
  });
}
