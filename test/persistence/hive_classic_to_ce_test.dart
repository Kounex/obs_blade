import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/app_log.dart';
import 'package:obs_blade/models/connection.dart';
import 'package:obs_blade/models/custom_theme.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/models/enums/dashboard_element.dart';
import 'package:obs_blade/models/hotkey.dart';
import 'package:obs_blade/models/past_stream_data.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';

import 'fixtures/foundation_data.dart';
import 'support/hive_test_harness.dart';

/// Boxes written by classic `hive: 2.2.3` only (see
/// `tool/classic_hive_writer/`), then opened with Hive CE — the real upgrade path.
void main() {
  final classicBoxes =
      Directory('test/persistence/fixtures/classic_boxes');
  late Directory tempDir;
  late HiveTestHarness harness;

  setUpAll(() {
    expect(
      classicBoxes.existsSync(),
      isTrue,
      reason:
          'Missing classic boxes. From repo root:\n'
          '  cd tool/classic_hive_writer && dart pub get && '
          'dart run bin/write_fixtures.dart '
          '../../test/persistence/fixtures/classic_boxes',
    );
    expect(
      classicBoxes
          .listSync()
          .whereType<File>()
          .any((f) => f.path.endsWith('.hive')),
      isTrue,
    );
  });

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('obs_blade_hive_classic_ce_');
    for (final entity in classicBoxes.listSync()) {
      if (entity is File && entity.path.endsWith('.hive')) {
        entity.copySync('${tempDir.path}/${entity.uri.pathSegments.last}');
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

  test('classic-written boxes open under Hive CE with foundation counts',
      () async {
    await harness.openAllBoxes();

    expect(Hive.box<Connection>(HiveKeys.SavedConnections.name).length,
        FixtureCounts.connections);
    expect(Hive.box<PastStreamData>(HiveKeys.PastStreamData.name).length,
        FixtureCounts.pastStreams);
    expect(Hive.box<CustomTheme>(HiveKeys.CustomTheme.name).length,
        FixtureCounts.themes);
    expect(Hive.box<AppLog>(HiveKeys.AppLog.name).length, FixtureCounts.appLogs);
    expect(Hive.box<Hotkey>(HiveKeys.Hotkey.name).length, FixtureCounts.hotkeys);
    expect(Hive.box(HiveKeys.Settings.name).length, greaterThan(10));
  });

  test('key foundation rows survive classic → CE open', () async {
    await harness.openAllBoxes();

    final livingRoom = Hive.box<Connection>(HiveKeys.SavedConnections.name)
        .values
        .firstWhere((c) => c.name == 'Living Room PC');
    expect(livingRoom.host, '192.168.1.50');
    expect(livingRoom.port, 4455);
    expect(livingRoom.pw, 'living-room-pw');
    expect(livingRoom.ssid, 'HomeWiFi-5G');

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
    expect(settings.get(SettingsKeys.BoughtBlacksmith.name), isTrue);
    expect(
      settings.get(SettingsKeys.DashboardElementsOrder.name),
      DashboardElement.values,
    );

    final raid = Hive.box<PastStreamData>(HiveKeys.PastStreamData.name)
        .values
        .firstWhere((s) => s.name == 'Starred Raid Night #0');
    expect(raid.starred, isTrue);
    expect(
      raid.kbitsPerSecList,
      hasLength(FixtureCounts.chartSamplesPerSession),
    );
  });

  test('classic → CE boxes still open after a second cold reopen', () async {
    await harness.openAllBoxes();
    await harness.reopenFromDisk();

    expect(Hive.box<Connection>(HiveKeys.SavedConnections.name).length,
        FixtureCounts.connections);
    expect(
      Hive.box<Connection>(HiveKeys.SavedConnections.name)
          .values
          .any((c) => c.name == 'Living Room PC'),
      isTrue,
    );
  });
}
