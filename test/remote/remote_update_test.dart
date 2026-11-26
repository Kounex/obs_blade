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
import 'package:obs_blade/stores/shared/remote_bridge_updates.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/pro_purchase_service.dart';
import 'package:obs_blade/utils/remote/remote_relay_client.dart';
import 'package:obs_blade/views/dashboard/widgets/remote_access/remote_update.dart';

import '../persistence/support/hive_test_harness.dart';
import '../pro/support/fake_pro_purchase_gateway.dart';

RemoteBridgeInfo _info({
  String id = 'b_1',
  String kind = 'standalone',
  String version = '0.4.1',
  String latest = '0.4.3',
  bool available = true,
  bool required = false,
}) => RemoteBridgeInfo(
  id: id,
  name: 'GAMING-PC',
  kind: kind,
  version: version,
  online: true,
  lastSeen: null,
  obsState: 'running',
  updateRequired: required,
  latestVersion: latest,
  updateAvailable: available,
  devices: const [],
);

void main() {
  group('RemoteBridgeUpdate', () {
    test('from the relay: available with a version, or required', () {
      final RemoteBridgeUpdate? update = RemoteBridgeUpdate.of(_info());
      expect(
        (update?.current, update?.latest, update?.required, update?.promptKey),
        ('0.4.1', '0.4.3', false, '0.4.3'),
      );
      expect(RemoteBridgeUpdate.of(_info(available: false)), isNull);
      // An older relay: no version, nothing to tell
      expect(RemoteBridgeUpdate.of(_info(latest: '')), isNull);
      final RemoteBridgeUpdate? required = RemoteBridgeUpdate.of(
        _info(available: false, latest: '', required: true),
      );
      expect((required?.required, required?.promptKey), (true, 'required'));
    });

    test('names the kind: plugin and app share a pairing', () {
      expect(RemoteBridgeUpdate.of(_info())!.name, 'OBS Blade Remote');
      expect(
        RemoteBridgeUpdate.of(_info(kind: 'plugin'))!.name,
        'the OBS Blade Remote plugin',
      );
    });
  });

  test('versions compare as releases', () {
    expect(remoteVersionBelow('0.4.1', '0.4.2'), isTrue);
    expect(remoteVersionBelow('0.3.9', '0.4.2'), isTrue);
    expect(remoteVersionBelow('0.4.2', '0.4.2'), isFalse);
    expect(remoteVersionBelow('0.10.0', '0.4.2'), isFalse);
    expect(remoteVersionBelow('', '0.4.2'), isFalse);
    expect(remoteVersionBelow('0.4.1-dev', '0.4.2'), isFalse);
  });

  test('the prompt comes once per PC and release', () {
    final RemoteBridgeUpdate update = RemoteBridgeUpdate.of(_info())!;
    expect(shouldPromptRemoteUpdate(update, 'b_1', {}), isTrue);
    expect(shouldPromptRemoteUpdate(update, 'b_1', {'b_1': '0.4.3'}), isFalse);
    expect(shouldPromptRemoteUpdate(update, 'b_2', {'b_1': '0.4.3'}), isTrue);
    expect(shouldPromptRemoteUpdate(update, 'b_1', {'b_1': '0.4.2'}), isTrue);
  });

  test('dialog copy: what the PC has, what is out, where to get it', () {
    expect(
      remoteUpdateDialogBody(
        RemoteBridgeUpdate.of(_info(kind: 'plugin', required: true))!,
        'GAMING-PC',
      ),
      startsWith(
        'GAMING-PC runs the OBS Blade Remote plugin 0.4.1, which remote '
        'access no longer works with. 0.4.3 is out.\n\n',
      ),
    );
    expect(
      remoteUpdateDialogBody(RemoteBridgeUpdate.of(_info())!, 'GAMING-PC'),
      'GAMING-PC runs OBS Blade Remote 0.4.1 - 0.4.3 is out.\n\nInstall it '
      'on the PC from obs-blade.kounex.com/remote, or share the link to open '
      'it there.',
    );
    expect(
      remoteUpdateDialogBody(
        RemoteBridgeUpdate.of(_info(kind: 'plugin', required: true))!,
        'GAMING-PC',
        reason: 'Why.',
      ),
      startsWith('Why. 0.4.3 is out.\n\nInstall it'),
    );
  });

  test('the app-wide holder follows the latest read per PC', () {
    final RemoteBridgeUpdates updates = RemoteBridgeUpdates();
    final Connection paired = Connection('192.168.1.20', 4455)
      ..relayBridgeId = 'b_1'
      ..relayAppToken = 'tok'
      ..relayDeviceId = 'd_me'
      ..relayAppKey = 'app-key'
      ..relayBridgeKey = 'bridge-key';
    expect(updates.updateFor(paired), isNull);
    updates.record(_info());
    expect(updates.updateFor(paired)?.latest, '0.4.3');
    updates.record(_info(id: 'b_other', available: false));
    expect(updates.updateFor(paired)?.latest, '0.4.3');
    // The PC got the update: the next read clears it
    updates.record(_info(version: '0.4.3', available: false));
    expect(updates.updateFor(paired), isNull);
    expect(updates.updateFor(Connection('192.168.1.21', 4455)), isNull);
  });

  group('connect prompt', () {
    late Directory tempDir;
    late HiveTestHarness harness;
    late Connection connection;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('remote_update');
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
      GetIt.instance.registerSingleton<RemoteBridgeUpdates>(
        RemoteBridgeUpdates(),
      );
      connection = Connection('192.168.1.20', 4455)
        ..name = 'Studio'
        ..relayBridgeId = 'b_1'
        ..relayAppToken = 'tok'
        ..relayDeviceId = 'd_me'
        ..relayAppKey = 'app-key'
        ..relayBridgeKey = 'bridge-key'
        ..relayBridgeName = 'GAMING-PC';
    });

    tearDown(() async {
      await GetIt.instance.reset();
      await harness.close();
      await tempDir.delete(recursive: true);
    });

    RemoteRelayClient relay({String latest = '0.4.3', bool available = true}) =>
        RemoteRelayClient(
          client: MockClient(
            (request) async => http.Response(
              jsonEncode({
                'id': 'b_1',
                'name': 'GAMING-PC',
                'kind': 'standalone',
                'version': '0.4.1',
                'online': true,
                'last_seen': 1794000000,
                'obs': 'running',
                'update_required': false,
                'latest_version': latest,
                'update_available': available,
                'devices': [],
              }),
              200,
              headers: {'content-type': 'application/json'},
            ),
          ),
        );

    Future<BuildContext> pumpHost(WidgetTester tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          theme: App.buildTheme(Hive.box(HiveKeys.Settings.name)),
          home: Scaffold(
            body: Builder(
              builder: (c) {
                context = c;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      return context;
    }

    Future<void> dismiss(WidgetTester tester) async {
      await tester.tap(find.text('Later'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('once per release: shown, remembered, shown for the next', (
      tester,
    ) async {
      final BuildContext context = await pumpHost(tester);

      await tester.runAsync(
        () => promptRemoteBridgeUpdate(context, connection, relay: relay()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Update OBS Blade Remote'), findsOneWidget);
      expect(
        find.textContaining('GAMING-PC runs OBS Blade Remote 0.4.1'),
        findsOneWidget,
      );
      expect(find.text('Share Link'), findsOneWidget);
      expect(
        GetIt.instance<RemoteBridgeUpdates>().updateFor(connection)?.latest,
        '0.4.3',
      );
      await dismiss(tester);

      // Same release on the next connect: the globe and the sheet remind
      await tester.runAsync(
        () => promptRemoteBridgeUpdate(context, connection, relay: relay()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Update OBS Blade Remote'), findsNothing);

      // A newer release: told again
      await tester.runAsync(
        () => promptRemoteBridgeUpdate(
          context,
          connection,
          relay: relay(latest: '0.4.4'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Update OBS Blade Remote'), findsOneWidget);
      await dismiss(tester);
    });

    testWidgets('nothing newer, or the relay unreachable: no prompt', (
      tester,
    ) async {
      final BuildContext context = await pumpHost(tester);
      await tester.runAsync(
        () => promptRemoteBridgeUpdate(
          context,
          connection,
          relay: relay(available: false),
        ),
      );
      final RemoteRelayClient down = RemoteRelayClient(
        client: MockClient((_) async => throw const SocketException('down')),
      );
      await tester.runAsync(
        () => promptRemoteBridgeUpdate(context, connection, relay: down),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Update OBS Blade Remote'), findsNothing);
      expect(
        Hive.box(
          HiveKeys.Settings.name,
        ).get(SettingsKeys.RemoteUpdatePrompted.name),
        isNull,
      );
    });
  });
}
