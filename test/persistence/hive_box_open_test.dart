import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/app_log.dart';
import 'package:obs_blade/models/connection.dart';
import 'package:obs_blade/models/custom_theme.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/models/enums/dashboard_element.dart';
import 'package:obs_blade/models/enums/log_level.dart';
import 'package:obs_blade/models/enums/scene_item_type.dart';
import 'package:obs_blade/models/hidden_scene.dart';
import 'package:obs_blade/models/hidden_scene_item.dart';
import 'package:obs_blade/models/hotkey.dart';
import 'package:obs_blade/models/past_record_data.dart';
import 'package:obs_blade/models/past_stream_data.dart';
import 'package:obs_blade/models/purchased_tip.dart';
import 'package:obs_blade/models/type_ids.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';

import 'fixtures/foundation_data.dart';
import 'support/hive_test_harness.dart';

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late HiveFoundationData foundation;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('obs_blade_hive_open_');
    harness = HiveTestHarness(tempDir);
    foundation = HiveFoundationData();
    await harness.init();
  });

  tearDown(() async {
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('TypeIDs (production contract)', () {
    test('remain the legacy 0–12 IDs shipped to existing installs', () {
      expect(TypeIDs.Connection, 0);
      expect(TypeIDs.PastStreamData, 1);
      expect(TypeIDs.CustomTheme, 2);
      expect(TypeIDs.HiddenSceneItem, 3);
      expect(TypeIDs.ChatType, 4);
      expect(TypeIDs.SceneItemType, 5);
      expect(TypeIDs.HiddenScene, 6);
      expect(TypeIDs.AppLog, 7);
      expect(TypeIDs.LogLevel, 8);
      expect(TypeIDs.PurchasedTip, 9);
      expect(TypeIDs.PastRecordData, 10);
      expect(TypeIDs.Hotkey, 11);
      expect(TypeIDs.DashboardElement, 12);
    });

    test('generated adapters expose the same typeIds', () {
      expect(ConnectionAdapter().typeId, TypeIDs.Connection);
      expect(PastStreamDataAdapter().typeId, TypeIDs.PastStreamData);
      expect(CustomThemeAdapter().typeId, TypeIDs.CustomTheme);
      expect(HiddenSceneItemAdapter().typeId, TypeIDs.HiddenSceneItem);
      expect(ChatTypeAdapter().typeId, TypeIDs.ChatType);
      expect(SceneItemTypeAdapter().typeId, TypeIDs.SceneItemType);
      expect(HiddenSceneAdapter().typeId, TypeIDs.HiddenScene);
      expect(AppLogAdapter().typeId, TypeIDs.AppLog);
      expect(LogLevelAdapter().typeId, TypeIDs.LogLevel);
      expect(PurchasedTipAdapter().typeId, TypeIDs.PurchasedTip);
      expect(PastRecordDataAdapter().typeId, TypeIDs.PastRecordData);
      expect(HotkeyAdapter().typeId, TypeIDs.Hotkey);
      expect(DashboardElementAdapter().typeId, TypeIDs.DashboardElement);
    });
  });

  group('Foundation data shape', () {
    test('exposes the expected volume of self-explanatory rows', () {
      expect(foundation.connections, hasLength(FixtureCounts.connections));
      expect(foundation.pastStreams, hasLength(FixtureCounts.pastStreams));
      expect(foundation.pastRecords, hasLength(FixtureCounts.pastRecords));
      expect(foundation.themes, hasLength(FixtureCounts.themes));
      expect(foundation.hiddenScenes, hasLength(FixtureCounts.hiddenScenes));
      expect(
          foundation.hiddenSceneItems, hasLength(FixtureCounts.hiddenSceneItems));
      expect(foundation.appLogs, hasLength(FixtureCounts.appLogs));
      expect(foundation.purchasedTips, hasLength(FixtureCounts.purchasedTips));
      expect(foundation.hotkeys, hasLength(FixtureCounts.hotkeys));
      expect(foundation.settings.keys, isNotEmpty);
    });

    test('connections cover password / domain / port edge cases by name', () {
      final byName = {
        for (final c in foundation.connections) c.name!: c,
      };
      expect(byName['Living Room PC']!.host, '192.168.1.50');
      expect(byName['Living Room PC']!.pw, 'living-room-pw');
      expect(byName['Office Mini-PC (no password)']!.pw, isNull);
      expect(byName['LAN DNS alias (isDomain=true)']!.isDomain, isTrue);
      expect(byName['Null port (client default)']!.port, isNull);
      expect(byName['Laptop Dock (custom port 4456)']!.port, 4456);
    });

    test('past streams carry dense chart lists', () {
      final raid = foundation.pastStreams.firstWhere(
        (s) => s.name == 'Starred Raid Night #0',
      );
      expect(raid.starred, isTrue);
      expect(raid.kbitsPerSecList, hasLength(FixtureCounts.chartSamplesPerSession));
      expect(raid.fpsList, hasLength(FixtureCounts.chartSamplesPerSession));
      expect(raid.cpuUsageList, hasLength(FixtureCounts.chartSamplesPerSession));
      expect(
          raid.memoryUsageList, hasLength(FixtureCounts.chartSamplesPerSession));
      expect(
          raid.listEntryDateMS, hasLength(FixtureCounts.chartSamplesPerSession));
    });
  });

  group('Open production boxes with foundation seed', () {
    test('every HiveKeys box opens and retains seeded counts', () async {
      await harness.seed(foundation);

      expect(Hive.box<Connection>(HiveKeys.SavedConnections.name).length,
          FixtureCounts.connections);
      expect(Hive.box<PastStreamData>(HiveKeys.PastStreamData.name).length,
          FixtureCounts.pastStreams);
      expect(Hive.box<PastRecordData>(HiveKeys.PastRecordData.name).length,
          FixtureCounts.pastRecords);
      expect(Hive.box<CustomTheme>(HiveKeys.CustomTheme.name).length,
          FixtureCounts.themes);
      expect(Hive.box<HiddenScene>(HiveKeys.HiddenScene.name).length,
          FixtureCounts.hiddenScenes);
      expect(Hive.box<HiddenSceneItem>(HiveKeys.HiddenSceneItem.name).length,
          FixtureCounts.hiddenSceneItems);
      expect(Hive.box<AppLog>(HiveKeys.AppLog.name).length, FixtureCounts.appLogs);
      expect(Hive.box<PurchasedTip>(HiveKeys.PurchasedTip.name).length,
          FixtureCounts.purchasedTips);
      expect(Hive.box<Hotkey>(HiveKeys.Hotkey.name).length, FixtureCounts.hotkeys);
      expect(Hive.box(HiveKeys.Settings.name).length, foundation.settings.length);
    });

    test('typed values round-trip through open boxes', () async {
      await harness.seed(foundation);

      final livingRoom = Hive.box<Connection>(HiveKeys.SavedConnections.name)
          .values
          .firstWhere((c) => c.name == 'Living Room PC');
      expect(livingRoom.host, '192.168.1.50');
      expect(livingRoom.port, 4455);
      expect(livingRoom.ssid, 'HomeWiFi-5G');

      final midnight = Hive.box<CustomTheme>(HiveKeys.CustomTheme.name)
          .values
          .firstWhere((t) => t.uuid == 'theme-uuid-midnight-blade');
      expect(midnight.accentColorHex, '3D8BFF');
      expect(midnight.useLightBrightness, isFalse);
      expect(midnight.starred, isTrue);

      final settings = Hive.box(HiveKeys.Settings.name);
      expect(settings.get(SettingsKeys.SelectedChatType.name), ChatType.Twitch);
      expect(settings.get(SettingsKeys.SelectedTwitchUsername.name), 'kounex');
      expect(
        settings.get(SettingsKeys.ActiveCustomThemeUUID.name),
        'theme-uuid-midnight-blade',
      );
      expect(
        settings.get(SettingsKeys.DashboardElementsOrder.name),
        DashboardElement.values,
      );

      final errorLogs = Hive.box<AppLog>(HiveKeys.AppLog.name)
          .values
          .where((l) => l.level == LogLevel.Error)
          .toList();
      expect(errorLogs, isNotEmpty);
      expect(errorLogs.first.stackTrace, contains('NetworkStore'));
    });

    test('hidden scene / item helpers still match after persistence', () async {
      await harness.seed(foundation);

      final scene = Hive.box<HiddenScene>(HiveKeys.HiddenScene.name)
          .values
          .firstWhere((s) => s.sceneName.startsWith('BRB'));
      expect(
        scene.isScene(scene.sceneName, scene.connectionName, scene.host),
        isTrue,
      );

      final audioItem = Hive.box<HiddenSceneItem>(HiveKeys.HiddenSceneItem.name)
          .values
          .firstWhere((i) => i.name == 'Mic/Aux');
      expect(audioItem.type, SceneItemType.Audio);
      expect(audioItem.id, isNull);
      expect(
        audioItem.isSceneItem(
          audioItem.sceneName,
          audioItem.type,
          audioItem.id,
          audioItem.name,
          audioItem.connectionName,
          audioItem.host,
        ),
        isTrue,
      );
    });
  });

  group('Cold reopen (upgrade-style open)', () {
    test('boxes reopen from disk without rewriting seed data', () async {
      await harness.seed(foundation);
      await harness.reopenFromDisk();

      expect(Hive.box<Connection>(HiveKeys.SavedConnections.name).length,
          FixtureCounts.connections);
      expect(Hive.box<PastStreamData>(HiveKeys.PastStreamData.name).length,
          FixtureCounts.pastStreams);
      expect(Hive.box<PastRecordData>(HiveKeys.PastRecordData.name).length,
          FixtureCounts.pastRecords);
      expect(Hive.box<CustomTheme>(HiveKeys.CustomTheme.name).length,
          FixtureCounts.themes);
      expect(Hive.box<HiddenScene>(HiveKeys.HiddenScene.name).length,
          FixtureCounts.hiddenScenes);
      expect(Hive.box<HiddenSceneItem>(HiveKeys.HiddenSceneItem.name).length,
          FixtureCounts.hiddenSceneItems);
      expect(Hive.box<AppLog>(HiveKeys.AppLog.name).length, FixtureCounts.appLogs);
      expect(Hive.box<PurchasedTip>(HiveKeys.PurchasedTip.name).length,
          FixtureCounts.purchasedTips);
      expect(Hive.box<Hotkey>(HiveKeys.Hotkey.name).length, FixtureCounts.hotkeys);

      final livingRoom = Hive.box<Connection>(HiveKeys.SavedConnections.name)
          .values
          .firstWhere((c) => c.name == 'Living Room PC');
      expect(livingRoom.pw, 'living-room-pw');

      final stream = Hive.box<PastStreamData>(HiveKeys.PastStreamData.name)
          .values
          .firstWhere((s) => s.name == 'Starred Raid Night #0');
      expect(stream.kbitsPerSecList.first, 2500);
      expect(stream.listEntryDateMS, hasLength(FixtureCounts.chartSamplesPerSession));

      final settings = Hive.box(HiveKeys.Settings.name);
      expect(settings.get(SettingsKeys.BoughtBlacksmith.name), isTrue);
      expect(
        (settings.get(SettingsKeys.TwitchUsernames.name) as List).length,
        3,
      );
      expect(
        (settings.get(SettingsKeys.YouTubeUsernames.name) as Map).length,
        2,
      );
    });

    test('reopen after copying hive files to a new directory', () async {
      await harness.seed(foundation);
      await harness.close();

      final cloneDir =
          await Directory.systemTemp.createTemp('obs_blade_hive_clone_');
      addTearDown(() {
        if (cloneDir.existsSync()) {
          cloneDir.deleteSync(recursive: true);
        }
      });

      for (final entity in tempDir.listSync()) {
        if (entity is File) {
          entity.copySync('${cloneDir.path}/${entity.uri.pathSegments.last}');
        }
      }

      final clone = HiveTestHarness(cloneDir);
      await clone.init();
      await clone.openAllBoxes();

      expect(Hive.box<Connection>(HiveKeys.SavedConnections.name).length,
          FixtureCounts.connections);
      expect(
        Hive.box<Connection>(HiveKeys.SavedConnections.name)
            .values
            .any((c) => c.name == 'Remote domain (stream.kounex.com)'),
        isTrue,
      );

      await clone.close();
    });
  });
}
