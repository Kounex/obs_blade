import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/purchase_base.dart';
import 'package:obs_blade/stores/pro_store.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/pro_ids.dart';
import 'package:obs_blade/utils/pro_purchase_service.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_pro_purchase_gateway.dart';

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeProPurchaseGateway gateway;
  late List<ProStore> stores;

  Box settingsBox() => Hive.box(HiveKeys.Settings.name);

  ProStore newStore() {
    final store = ProStore(service: ProPurchaseService(gateway: gateway));
    stores.add(store);
    return store;
  }

  setUp(() async {
    tempDir = Directory(
      '${Directory.systemTemp.path}/pro_store_test_${DateTime.now().microsecondsSinceEpoch}',
    );
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();
    gateway = FakeProPurchaseGateway();
    stores = [];
    PurchaseBase.restoreTriggeredExplicitly = false;
  });

  tearDown(() async {
    for (final store in stores) {
      store.dispose();
    }
    await gateway.close();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('entitlement', () {
    test('no flag, no override → not Pro', () {
      final store = newStore()..init();

      expect(store.isPro, isFalse);
    });

    test('BoughtPro flag in settings box → isPro', () {
      settingsBox().put(SettingsKeys.BoughtPro.name, true);

      final store = newStore()..init();

      expect(store.boughtPro, isTrue);
      expect(store.isPro, isTrue);
    });

    test('box watcher picks up PurchaseBase flag writes', () async {
      final store = newStore()..init();
      expect(store.isPro, isFalse);

      settingsBox().put(SettingsKeys.BoughtPro.name, true);
      await until(() => store.isPro);

      expect(store.boughtPro, isTrue);
    });

    test('debug override grants isPro only under kDebugMode', () async {
      /// Tests always run in debug — this pins the precondition the
      /// `kDebugMode &&` gate in `isPro` relies on. In release builds the
      /// override short-circuits to false regardless of the box value.
      expect(kDebugMode, isTrue);

      final store = newStore()..init();
      expect(store.isPro, isFalse);

      settingsBox().put(SettingsKeys.ProDebugOverride.name, true);
      await until(() => store.debugOverride);

      expect(store.boughtPro, isFalse);
      expect(store.isPro, isTrue);
    });

    test('setDebugOverride writes the box key (debug)', () async {
      final store = newStore()..init();

      store.setDebugOverride(true);
      await until(() => store.isPro);

      expect(settingsBox().get(SettingsKeys.ProDebugOverride.name), isTrue);
      expect(store.isPro, isTrue);
    });
  });

  group('products', () {
    test('loadProducts populates products from the store', () async {
      gateway.storeProducts = [
        fakeProduct(kProYearlyId),
        fakeProduct(kProMonthlyId),
      ];
      final store = newStore()..init();

      await store.loadProducts();

      expect(store.products.map((product) => product.id), [
        kProYearlyId,
        kProMonthlyId,
      ]);
      expect(store.lastError, isNull);
      expect(store.pending, isFalse);
    });

    test(
      'products missing store-side → empty graceful state, no error',
      () async {
        final store = newStore()..init();

        await store.loadProducts();

        expect(store.products, isEmpty);
        expect(store.lastError, isNull);
      },
    );

    test('store unavailable → lastError, empty products, no crash', () async {
      gateway.available = false;
      final store = newStore()..init();

      await store.loadProducts();

      expect(store.products, isEmpty);
      expect(store.lastError, 'store-unavailable');
      expect(store.pending, isFalse);
    });

    test('query error → lastError, empty products', () async {
      gateway.queryError = StateError('store exploded');
      final store = newStore()..init();

      await store.loadProducts();

      expect(store.products, isEmpty);
      expect(store.lastError, contains('store exploded'));
      expect(store.pending, isFalse);
    });
  });

  group('buy', () {
    test('buy delegates to the gateway and toggles pending', () async {
      final store = newStore()..init();

      final result = await store.buy(fakeProProduct(kProYearlyId));

      expect(result, isTrue);
      expect(gateway.buyCalls, 1);
      expect(gateway.lastBoughtProduct?.id, kProYearlyId);
      expect(store.pending, isFalse);
      expect(store.lastError, isNull);
    });

    test('buy error → false + lastError', () async {
      gateway.buyError = StateError('buy failed');
      final store = newStore()..init();

      final result = await store.buy(fakeProProduct(kProYearlyId));

      expect(result, isFalse);
      expect(gateway.buyCalls, 1);
      expect(store.lastError, contains('buy failed'));
      expect(store.pending, isFalse);
    });
  });

  group('restore', () {
    test('explicit restore arms the dialog flag in flight and disarms it when '
        'the restore completes without a pro event', () async {
      final store = newStore()..init();

      /// Let the cold-start restore finish first so only the explicit
      /// restore is in flight for the flag assertions.
      await until(() => gateway.restoreCalls > 0);

      bool? armedInFlight;
      gateway.onRestore = () =>
          armedInFlight = PurchaseBase.restoreTriggeredExplicitly;

      await store.restore(explicit: true);

      expect(gateway.restoreCalls, 2);
      expect(armedInFlight, isTrue);

      /// No pro restored event consumed the flag — it must be disarmed so a
      /// later spontaneous restored event can't show the dialog unprovoked.
      expect(PurchaseBase.restoreTriggeredExplicitly, isFalse);
    });

    test('silent restore leaves the dialog flag alone', () async {
      final store = newStore()..init();

      await store.restore(explicit: false);

      expect(PurchaseBase.restoreTriggeredExplicitly, isFalse);
    });

    test(
      'restore error disarms the dialog flag and records lastError',
      () async {
        final store = newStore()..init();
        await until(() => gateway.restoreCalls > 0);

        gateway.restoreError = StateError('restore failed');
        await store.restore(explicit: true);

        expect(PurchaseBase.restoreTriggeredExplicitly, isFalse);
        expect(store.lastError, contains('restore failed'));
      },
    );
  });

  group('cold-start restore', () {
    test('fires once per install (guard flag in settings box)', () async {
      newStore().init();
      await until(() => gateway.restoreCalls > 0);

      expect(gateway.restoreCalls, 1);
      expect(
        settingsBox().get(
          SettingsKeys.ProColdStartRestoreDone.name,
          defaultValue: false,
        ),
        isTrue,
      );

      /// A second store (next app launch) must not restore again — the
      /// guard short-circuits before any store call.
      newStore().init();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(gateway.restoreCalls, 1);
    });

    test(
      'store unavailable → one shot not burned, retried next launch',
      () async {
        gateway.available = false;
        newStore().init();
        await until(() => gateway.isAvailableCalls > 0);

        expect(gateway.restoreCalls, 0);
        expect(
          settingsBox().get(
            SettingsKeys.ProColdStartRestoreDone.name,
            defaultValue: false,
          ),
          isFalse,
        );

        gateway.available = true;
        newStore().init();
        await until(() => gateway.restoreCalls > 0);

        expect(gateway.restoreCalls, 1);
      },
    );

    test(
      'restore error leaves the guard flag unset (retried next launch)',
      () async {
        gateway.restoreError = StateError('boom');
        newStore().init();
        await until(() => gateway.restoreCalls > 0);

        expect(gateway.restoreCalls, 1);
        expect(
          settingsBox().get(
            SettingsKeys.ProColdStartRestoreDone.name,
            defaultValue: false,
          ),
          isFalse,
        );

        /// Next launch: the transient error is gone, the restore retried and
        /// the guard flag set only now.
        gateway.restoreError = null;
        newStore().init();
        await until(() => gateway.restoreCalls > 1);

        expect(
          settingsBox().get(
            SettingsKeys.ProColdStartRestoreDone.name,
            defaultValue: false,
          ),
          isTrue,
        );
      },
    );
  });
}
