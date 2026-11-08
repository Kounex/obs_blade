import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/connection.dart';
import 'package:obs_blade/shared/general/hive_builder.dart';
import 'package:obs_blade/stores/views/home.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/remote_reach.dart';
import 'package:obs_blade/utils/remote/remote_connect.dart';
import 'package:obs_blade/utils/remote/remote_relay_client.dart';
import 'package:obs_blade/views/home/widgets/saved_connections/reachable_builder.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

/// The saved-connection cards: [ReachableBuilder] sits under a [HiveBuilder]
/// that rebuilds on every box change, so its list has to follow the box.
void main() {
  late Directory tempDir;
  late Box<Connection> box;
  late int deadPort;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('obs_blade_reachable_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter<Connection>(ConnectionAdapter());
    }
    box = await Hive.openBox<Connection>(HiveKeys.SavedConnections.name);
    GetIt.instance.registerSingleton<HomeStore>(HomeStore());

    /// Nothing listens here - checks fail fast with "connection refused"
    final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    deadPort = probe.port;
    await probe.close();
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  Connection saved(String name) =>
      Connection(InternetAddress.loopbackIPv4.address, deadPort)..name = name;

  Widget subject({RemoteConnectEnvironment? remote}) => MaterialApp(
    home: HiveBuilder<Connection>(
      hiveKey: HiveKeys.SavedConnections,
      builder: (context, _, _) => ReachableBuilder(
        remote: remote,
        savedConnectionsBuilder: (connections) => Column(
          children: [
            for (final connection in connections) Text(connection.name!),
          ],
        ),
      ),
    ),
  );

  /// The reachability check runs on a real isolate with real socket I/O -
  /// poll (a real-time window plus a pump per round, so the check can
  /// finish and the rebuild can land) until the result is visible instead
  /// of betting on a fixed settle window
  Future<void> pumpUntil(
    WidgetTester tester,
    bool Function() condition,
    String description,
  ) async {
    for (var i = 0; i < 250; i++) {
      if (condition()) return;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    fail('Timed out waiting for: $description');
  }

  testWidgets('a deleted connection disappears, an added one appears', (
    tester,
  ) async {
    late Connection alpha;
    await tester.runAsync(() async {
      alpha = saved('Alpha');
      await box.add(alpha);
      await box.add(saved('Beta'));
    });

    await tester.pumpWidget(subject());
    await pumpUntil(
      tester,
      () =>
          find.text('Alpha').evaluate().isNotEmpty &&
          find.text('Beta').evaluate().isNotEmpty,
      'initial check resolves',
    );
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);

    await tester.runAsync(() => alpha.delete());
    await pumpUntil(
      tester,
      () => find.text('Alpha').evaluate().isEmpty,
      'deletion lands',
    );
    expect(find.text('Alpha'), findsNothing);
    expect(find.text('Beta'), findsOneWidget);

    await tester.runAsync(() => box.add(saved('Gamma')));
    await pumpUntil(
      tester,
      () => find.text('Gamma').evaluate().isNotEmpty,
      'addition lands',
    );
    expect(find.text('Gamma'), findsOneWidget);
  });

  testWidgets('an edited endpoint is checked again', (tester) async {
    late Connection alpha;
    await tester.runAsync(() async {
      alpha = saved('Alpha');
      await box.add(alpha);
    });

    await tester.pumpWidget(subject());
    await pumpUntil(
      tester,
      () => alpha.reachable == false,
      'initial check resolves',
    );
    expect(alpha.reachable, isFalse);

    await tester.runAsync(() async {
      alpha.port = deadPort + 1;
      await alpha.save();
    });

    /// Reset to "checking" for the new endpoint (set during the rebuild,
    /// so it is always observed before the next real-time window lets the
    /// re-check resolve), then resolved again
    await pumpUntil(tester, () => alpha.reachable == null, 're-check starts');
    expect(alpha.reachable, isNull);
    await pumpUntil(
      tester,
      () => alpha.reachable == false,
      're-check resolves',
    );
    expect(alpha.reachable, isFalse);
  });

  testWidgets('a "Last used" stamp alone does not re-check', (tester) async {
    late Connection alpha;
    await tester.runAsync(() async {
      alpha = saved('Alpha');
      await box.add(alpha);
    });

    await tester.pumpWidget(subject());
    await pumpUntil(
      tester,
      () => alpha.reachable == false,
      'initial check resolves',
    );

    await tester.runAsync(() async {
      alpha.lastConnectedMs = 1;
      await alpha.save();
    });
    await tester.pump();

    expect(alpha.reachable, isFalse);
  });

  group('paired connections ask the relay', () {
    /// GET /v1/bridges/{id} answers per bridge id, as tool/remote_relay
    /// does: 200 with online / obs, or 401 for a revoked pairing
    late Map<String, (int, bool, String)> bridges;
    late bool isPro;

    RemoteConnectEnvironment env() => RemoteConnectEnvironment(
      isPro: () => isPro,
      onLocalNetwork: () async => true,
      appUserId: () async => 'x',
      relay: RemoteRelayClient(
        baseUrl: 'https://relay.example',
        client: MockClient((request) async {
          final (status, online, obs) =
              bridges[request.url.pathSegments.last] ?? (404, false, '');
          return http.Response(
            jsonEncode(
              status == 200
                  ? {
                      'id': 'b',
                      'name': 'PC',
                      'kind': 'standalone',
                      'online': online,
                      'obs': obs,
                      'devices': [],
                    }
                  : {'error': 'unpaired'},
            ),
            status,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );

    Connection paired(String name, String bridgeId) => saved(name)
      ..relayBridgeId = bridgeId
      ..relayAppToken = 'tok'
      ..relayDeviceId = 'd'
      ..relayBridgeName = 'PC'
      ..relayBridgeKind = 'standalone';

    setUp(() {
      isPro = true;
      bridges = {
        'running': (200, true, 'running'),
        'closed': (200, true, 'closed'),
        'wsoff': (200, true, 'ws_off'),
        'offline': (200, false, 'closed'),
        'revoked': (401, false, ''),
      };
    });

    testWidgets(
      'LAN out of reach: the relay decides Online and the line',
      timeout: const Timeout(Duration(seconds: 90)),
      (tester) async {
        final cards = {
          for (final id in ['running', 'closed', 'wsoff', 'offline', 'revoked'])
            id: paired(id, id),
        };
        await tester.runAsync(() async {
          for (final c in cards.values) {
            await box.add(c);
          }
        });

        await tester.pumpWidget(subject(remote: env()));
        await pumpUntil(
          tester,
          () => cards.values.every((c) => c.reachable != null),
          'checks resolve',
        );

        expect(
          {
            for (final e in cards.entries)
              e.key: (e.value.reachable, e.value.remoteReach),
          },
          {
            'running': (true, RemoteReach.obsRunning),
            'closed': (false, RemoteReach.obsNotRunning),
            'wsoff': (false, RemoteReach.obsUnreachable),
            'offline': (false, RemoteReach.pcOffline),
            'revoked': (false, null),
          },
        );
        expect(
          cards['revoked']!.hasRemote,
          isFalse,
          reason: 'a revoked pairing is forgotten',
        );

        /// Let the forget's Hive write land before tearDown closes the box
        for (var i = 0; i < 10; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump();
        }
        await tester.runAsync(() => box.flush());
        expect(
          box.values.firstWhere((c) => c.name == 'revoked').relayAppToken,
          isNull,
        );
        expect(RemoteReach.obsRunning.cardProblem, isNull);
        expect(RemoteReach.pcOffline.cardProblem, 'PC offline');
      },
    );

    testWidgets('without Pro the relay is not asked', (tester) async {
      isPro = false;
      final c = paired('running', 'running');
      await tester.runAsync(() => box.add(c));

      await tester.pumpWidget(subject(remote: env()));
      await pumpUntil(tester, () => c.reachable != null, 'check resolves');

      expect((c.reachable, c.remoteReach), (false, null));
    });
  });
}
