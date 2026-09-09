import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/stores/pro_store.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/pro_purchase_service.dart';
import 'package:obs_blade/views/settings/custom_theme/custom_theme.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_pro_purchase_gateway.dart';

/// The custom-theme gate: legacy blacksmith owners (offline-friendly Hive
/// flag) OR live [ProStore.isPro]. Blacksmith is intentionally NOT folded
/// into the Pro entitlement — both unlocks stand alone.
void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeProPurchaseGateway gateway;
  late List<ProStore> stores;

  Box<dynamic> settingsBox() => Hive.box(HiveKeys.Settings.name);

  ProStore newStore() {
    final store = ProStore(service: ProPurchaseService(gateway: gateway));
    stores.add(store);
    return store;
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('custom_theme_unlock');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();
    gateway = FakeProPurchaseGateway();
    stores = [];
  });

  tearDown(() async {
    for (final store in stores) {
      store.dispose();
    }
    if (GetIt.instance.isRegistered<ProStore>()) {
      GetIt.instance.unregister<ProStore>();
    }
    await gateway.close();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('neither blacksmith nor Pro → locked', () {
    final store = newStore()..init();

    expect(customThemesUnlocked(settingsBox(), proStore: store), isFalse);
  });

  test('legacy blacksmith flag alone → unlocked (offline-friendly)', () {
    settingsBox().put(SettingsKeys.BoughtBlacksmith.name, true);
    final store = newStore()..init();

    expect(store.isPro, isFalse);
    expect(customThemesUnlocked(settingsBox(), proStore: store), isTrue);
  });

  test('Pro alone → unlocked', () {
    settingsBox().put(SettingsKeys.BoughtPro.name, true);
    final store = newStore()..init();

    expect(store.isPro, isTrue);
    expect(customThemesUnlocked(settingsBox(), proStore: store), isTrue);
  });

  test('default GetIt ProStore is used when none is passed', () {
    settingsBox().put(SettingsKeys.BoughtPro.name, true);
    final store = newStore()..init();
    GetIt.instance.registerSingleton<ProStore>(store);

    expect(customThemesUnlocked(settingsBox()), isTrue);
  });
}
