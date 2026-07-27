import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/connection.dart';
import 'package:obs_blade/models/custom_theme.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/models/past_stream_data.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';

import 'fixtures/foundation_data.dart';
import 'support/hive_test_harness.dart';

/// Opens pre-written Hive box files (no seed in this test).
///
/// Simulates an app upgrade: existing on-disk boxes must open under Hive CE.
void main() {
  final fixtureBoxes = Directory('test/persistence/fixtures/boxes');
  late Directory tempDir;
  late HiveTestHarness harness;

  setUpAll(() {
    expect(
      fixtureBoxes.existsSync(),
      isTrue,
      reason:
          'Missing committed boxes. Run: flutter test test/persistence/generate_committed_boxes_test.dart',
    );
    expect(
      fixtureBoxes.listSync().whereType<File>().any((f) => f.path.endsWith('.hive')),
      isTrue,
    );
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('obs_blade_hive_committed_');
    for (final entity in fixtureBoxes.listSync()) {
      if (entity is File && entity.path.endsWith('.hive')) {
        entity.copySync(
          '${tempDir.path}/${entity.uri.pathSegments.last}',
        );
      }
    }
    harness = HiveTestHarness(tempDir);
    await harness.init();
  });

  tearDown(() async {
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('all production boxes open from committed fixtures', () async {
    await harness.openAllBoxes();

    expect(Hive.box<Connection>(HiveKeys.SavedConnections.name).length,
        FixtureCounts.connections);
    expect(Hive.box<PastStreamData>(HiveKeys.PastStreamData.name).length,
        FixtureCounts.pastStreams);
    expect(Hive.box(HiveKeys.Settings.name).isOpen, isTrue);
    expect(Hive.box(HiveKeys.Settings.name).length, greaterThan(10));
  });

  test('committed connection + theme + settings values survive cold open',
      () async {
    await harness.openAllBoxes();

    final livingRoom = Hive.box<Connection>(HiveKeys.SavedConnections.name)
        .values
        .firstWhere((c) => c.name == 'Living Room PC');
    expect(livingRoom.host, '192.168.1.50');
    expect(livingRoom.port, 4455);
    expect(livingRoom.pw, 'living-room-pw');

    final theme = Hive.box<CustomTheme>(HiveKeys.CustomTheme.name)
        .values
        .firstWhere((t) => t.uuid == 'theme-uuid-midnight-blade');
    expect(theme.name, 'Midnight Blade');
    expect(theme.accentColorHex, '3D8BFF');

    final settings = Hive.box(HiveKeys.Settings.name);
    expect(settings.get(SettingsKeys.SelectedChatType.name), ChatType.Twitch);
    expect(
      settings.get(SettingsKeys.ActiveCustomThemeUUID.name),
      'theme-uuid-midnight-blade',
    );

    final raid = Hive.box<PastStreamData>(HiveKeys.PastStreamData.name)
        .values
        .firstWhere((s) => s.name == 'Starred Raid Night #0');
    expect(raid.starred, isTrue);
    expect(raid.kbitsPerSecList, hasLength(FixtureCounts.chartSamplesPerSession));
  });

  test('second reopen of the same committed files still works', () async {
    await harness.openAllBoxes();
    await harness.reopenFromDisk();

    expect(Hive.box<Connection>(HiveKeys.SavedConnections.name).length,
        FixtureCounts.connections);
    expect(
      Hive.box<Connection>(HiveKeys.SavedConnections.name)
          .values
          .any((c) => c.name == 'mDNS host obs-main.local'),
      isTrue,
    );
  });
}
