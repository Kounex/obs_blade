import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:obs_blade/purchase_base.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/pro_ids.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_pro_purchase_gateway.dart';

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;

  Box settingsBox() => Hive.box(HiveKeys.Settings.name);

  setUp(() async {
    tempDir = Directory(
      '${Directory.systemTemp.path}/purchase_base_pro_test_${DateTime.now().microsecondsSinceEpoch}',
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

  group('applyProPurchaseToSettings', () {
    test('purchased → sets BoughtPro, no dialog', () {
      final showDialog = applyProPurchaseToSettings(
        purchaseDetails: fakePurchase(kProYearlyId, PurchaseStatus.purchased),
        settingsBox: settingsBox(),
        explicitRestore: false,
      );

      expect(settingsBox().get(SettingsKeys.BoughtPro.name), isTrue);
      expect(showDialog, isFalse);
    });

    test('restored + explicit restore → sets BoughtPro, dialog requested', () {
      final showDialog = applyProPurchaseToSettings(
        purchaseDetails: fakePurchase(kProLifetimeId, PurchaseStatus.restored),
        settingsBox: settingsBox(),
        explicitRestore: true,
      );

      expect(settingsBox().get(SettingsKeys.BoughtPro.name), isTrue);
      expect(showDialog, isTrue);
    });

    test('restored via cold-start (silent) → sets BoughtPro, no dialog', () {
      final showDialog = applyProPurchaseToSettings(
        purchaseDetails: fakePurchase(kProMonthlyId, PurchaseStatus.restored),
        settingsBox: settingsBox(),
        explicitRestore: false,
      );

      expect(settingsBox().get(SettingsKeys.BoughtPro.name), isTrue);
      expect(showDialog, isFalse);
    });
  });

  test('isProProductId matches exactly the pro product ids', () {
    expect(isProProductId(kProYearlyId), isTrue);
    expect(isProProductId(kProMonthlyId), isTrue);
    expect(isProProductId(kProLifetimeId), isTrue);

    expect(isProProductId('blacksmith'), isFalse);
    expect(isProProductId('tip_beer'), isFalse);
    expect(isProProductId('pro_yearly_extra'), isFalse);
    expect(isProProductId(''), isFalse);
  });
}
