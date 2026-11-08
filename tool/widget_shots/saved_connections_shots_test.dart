import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/connection.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/home.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/views/home/widgets/saved_connections/saved_connections.dart';

import 'support/shots_harness.dart';

/// Home's saved connections at the card size (192 x 292, 2026-11-08):
/// the phone carousel with its neighbors peeking, a 320 pt phone (the card
/// narrows) and the tablet row.
void main() {
  final harness = ShotsHarness();

  setUpAll(ShotsHarness.loadFonts);

  setUp(() async {
    await harness.setUp();
    GetIt.instance
      ..registerSingleton<NetworkStore>(NetworkStore())
      ..registerSingleton<HomeStore>(HomeStore());
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await harness.tearDown();
  });

  testWidgets('saved connections', (tester) async {
    await tester.runAsync(() async {
      final box = Hive.box<Connection>(HiveKeys.SavedConnections.name);
      for (final (name, host) in [
        ('GAMING-PC', '192.168.178.20'),
        ('Studio', '192.168.178.31'),
        ('Laptop', '192.168.178.44'),
      ]) {
        await box.add(
          Connection(host, 4455)
            ..name = name
            ..lastConnectedMs =
                DateTime.now().millisecondsSinceEpoch - 2 * 3600 * 1000,
        );
      }
      await box.flush();
    });
    const Widget section = SingleChildScrollView(child: SavedConnections());
    await harness.shot(tester, 'saved_connections', section);
    await harness.shot(
      tester,
      'saved_connections_narrow',
      section,
      size: const Size(320, 640),
    );
    await harness.shot(
      tester,
      'saved_connections_promax',
      section,
      size: const Size(440, 956),
    );
    await harness.shot(
      tester,
      'saved_connections_tablet',
      section,
      size: kShotTablet,
    );
  });
}
