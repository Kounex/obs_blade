import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/app_log.dart';
import 'package:obs_blade/models/enums/log_level.dart';
import 'package:obs_blade/models/hotkey.dart';
import 'package:obs_blade/models/past_record_data.dart';
import 'package:obs_blade/models/past_stream_data.dart';
import 'package:obs_blade/models/purchased_tip.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/settings/data_management/data_management.dart';

import '../persistence/support/hive_test_harness.dart';

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;

  Box settingsBox() => Hive.box(HiveKeys.Settings.name);

  setUp(() async {
    tempDir = Directory(
      '${Directory.systemTemp.path}/data_management_pro_test_${DateTime.now().microsecondsSinceEpoch}',
    );
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();
  });

  tearDown(() async {
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test(
    'delete-all preserves BoughtPro and BoughtBlacksmith, clears the rest',
    () async {
      settingsBox().put(SettingsKeys.BoughtPro.name, true);
      settingsBox().put(SettingsKeys.BoughtBlacksmith.name, true);
      settingsBox().put(SettingsKeys.TrueDark.name, true);
      settingsBox().put(SettingsKeys.ProColdStartRestoreDone.name, true);
      Hive.box<AppLog>(HiveKeys.AppLog.name).add(
        AppLog(
          DateTime.now().millisecondsSinceEpoch,
          LogLevel.Info,
          'entry',
          null,
          false,
        ),
      );

      await deleteAllUserDataPreservingEntitlements();

      expect(settingsBox().get(SettingsKeys.BoughtPro.name), isTrue);
      expect(settingsBox().get(SettingsKeys.BoughtBlacksmith.name), isTrue);
      expect(settingsBox().get(SettingsKeys.TrueDark.name), isNull);
      expect(
        settingsBox().get(SettingsKeys.ProColdStartRestoreDone.name),
        isNull,
      );
      expect(Hive.box<AppLog>(HiveKeys.AppLog.name).isEmpty, isTrue);
    },
  );

  test('delete-all with no purchases → flags re-set to false', () async {
    settingsBox().put(SettingsKeys.TrueDark.name, true);

    await deleteAllUserDataPreservingEntitlements();

    expect(settingsBox().get(SettingsKeys.BoughtPro.name), isFalse);
    expect(settingsBox().get(SettingsKeys.BoughtBlacksmith.name), isFalse);
    expect(settingsBox().get(SettingsKeys.TrueDark.name), isNull);
  });

  test(
    'delete-all clears recordings, hotkeys and purchased tips too',
    () async {
      await Hive.box<PastStreamData>(
        HiveKeys.PastStreamData.name,
      ).add(PastStreamData());
      await Hive.box<PastRecordData>(
        HiveKeys.PastRecordData.name,
      ).add(PastRecordData());
      await Hive.box<Hotkey>(HiveKeys.Hotkey.name).add(Hotkey('My Hotkey'));
      await Hive.box<PurchasedTip>(
        HiveKeys.PurchasedTip.name,
      ).add(PurchasedTip(0, 'tip-1', 'Coffee', '4.99', r'$'));

      await deleteAllUserDataPreservingEntitlements();

      expect(
        Hive.box<PastStreamData>(HiveKeys.PastStreamData.name).isEmpty,
        isTrue,
      );
      expect(
        Hive.box<PastRecordData>(HiveKeys.PastRecordData.name).isEmpty,
        isTrue,
      );
      expect(Hive.box<Hotkey>(HiveKeys.Hotkey.name).isEmpty, isTrue);
      expect(
        Hive.box<PurchasedTip>(HiveKeys.PurchasedTip.name).isEmpty,
        isTrue,
      );
    },
  );
}
