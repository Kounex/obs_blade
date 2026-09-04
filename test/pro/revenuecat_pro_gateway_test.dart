import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/purchase_base.dart';
import 'package:obs_blade/stores/pro_store.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/pro_ids.dart';
import 'package:obs_blade/utils/pro_purchase_service.dart';
import 'package:obs_blade/utils/revenuecat_config.dart';
import 'package:obs_blade/utils/revenuecat_pro_gateway.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_pro_purchase_backend.dart';
import 'support/fake_pro_purchase_gateway.dart';

/// Minimal `Package` JSON as the native SDK would deliver it — the
/// translation seam parses these via RevenueCat's own `fromJson`, so no
/// platform channel is involved.
Package fakePackage(
  String productId, {
  String packageIdentifier = '\$rc_annual',
  String priceString = '€19.99',
  String? subscriptionPeriod = 'P1Y',
}) =>
    Package.fromJson({
      'identifier': packageIdentifier,
      'packageType': 'CUSTOM',
      'product': {
        'identifier': productId,
        'description': 'description $productId',
        'title': 'Pro ($productId)',
        'price': 19.99,
        'priceString': priceString,
        'currencyCode': 'EUR',
        'subscriptionPeriod': subscriptionPeriod,
      },
      'presentedOfferingContext': {'offeringIdentifier': 'default'},
    });

Map<String, dynamic> _entitlementJson({required bool active}) => {
      'identifier': kProEntitlementId,
      'isActive': active,
      'willRenew': active,
      'latestPurchaseDate': '2026-09-01T00:00:00Z',
      'originalPurchaseDate': '2026-09-01T00:00:00Z',
      'productIdentifier': kProYearlyId,
      'isSandbox': true,
      if (!active) 'expirationDate': '2026-09-02T00:00:00Z',
    };

/// Minimal `CustomerInfo` JSON — `active` mirrors the dashboard state:
/// expired entitlements stay in `all` but drop out of `active`.
CustomerInfo fakeCustomerInfo({required bool proActive}) {
  final entitlement = _entitlementJson(active: proActive);
  return CustomerInfo.fromJson({
    'entitlements': {
      'all': {kProEntitlementId: entitlement},
      'active': proActive ? {kProEntitlementId: entitlement} : <String, dynamic>{},
    },
    'allPurchaseDates': const <String, dynamic>{},
    'activeSubscriptions': proActive ? [kProYearlyId] : const <String>[],
    'allPurchasedProductIdentifiers': proActive
        ? [kProYearlyId]
        : const <String>[],
    'nonSubscriptionTransactions': const <dynamic>[],
    'firstSeen': '2026-09-01T00:00:00Z',
    'originalAppUserId': 'test-user',
    'allExpirationDates': const <String, dynamic>{},
    'requestDate': '2026-09-03T00:00:00Z',
  });
}

void main() {
  group('proProductFromPackage', () {
    test('maps the store product fields (package id is NOT the product id)',
        () {
      final product = proProductFromPackage(fakePackage(kProYearlyId));

      expect(product.id, kProYearlyId);
      expect(product.title, 'Pro ($kProYearlyId)');
      expect(product.priceString, '€19.99');
      expect(product.subscriptionPeriod, 'P1Y');
      expect(product.storeObject, isA<Package>());
    });

    test('lifetime package → null subscription period', () {
      final product = proProductFromPackage(
        fakePackage(
          kProLifetimeId,
          packageIdentifier: '\$rc_lifetime',
          subscriptionPeriod: null,
        ),
      );

      expect(product.id, kProLifetimeId);
      expect(product.subscriptionPeriod, isNull);
    });
  });

  group('proEntitlementActive', () {
    test('active pro entitlement → true', () {
      expect(proEntitlementActive(fakeCustomerInfo(proActive: true)), isTrue);
    });

    test('expired pro entitlement (in all, not active) → false — the '
        'lapsed-subscription case the legacy path cannot detect', () {
      expect(proEntitlementActive(fakeCustomerInfo(proActive: false)), isFalse);
    });

    test('no pro entitlement at all → false', () {
      final info = CustomerInfo.fromJson({
        'entitlements': {
          'all': <String, dynamic>{},
          'active': <String, dynamic>{},
        },
        'allPurchaseDates': const <String, dynamic>{},
        'activeSubscriptions': const <String>[],
        'allPurchasedProductIdentifiers': const <String>[],
        'nonSubscriptionTransactions': const <dynamic>[],
        'firstSeen': '2026-09-01T00:00:00Z',
        'originalAppUserId': 'test-user',
        'allExpirationDates': const <String, dynamic>{},
        'requestDate': '2026-09-03T00:00:00Z',
      });

      expect(proEntitlementActive(info), isFalse);
    });
  });

  group('backend selection', () {
    /// The repo ships with EMPTY RevenueCat keys — this pins the dual-path
    /// default. Once the maintainer fills the keys in
    /// `revenuecat_config.dart`, this test SHOULD be revisited (it will
    /// fail on iOS/Android-typed platforms by design).
    test('empty keys → RevenueCat not configured, default service uses the '
        'legacy IAP backend', () {
      expect(kRevenueCatAppleApiKey, isEmpty);
      expect(kRevenueCatGoogleApiKey, isEmpty);
      expect(revenueCatConfigured, isFalse);
      expect(ProPurchaseService().handlesEntitlement, isFalse);
    });
  });

  group('ProStore on the RevenueCat path', () {
    late Directory tempDir;
    late HiveTestHarness harness;
    late FakeProPurchaseBackend backend;
    late List<ProStore> stores;

    Box settingsBox() => Hive.box(HiveKeys.Settings.name);

    ProStore newStore() {
      final store = ProStore(
        service: ProPurchaseService(backend: backend),
      );
      stores.add(store);
      return store;
    }

    setUp(() async {
      tempDir = Directory(
          '${Directory.systemTemp.path}/pro_store_rc_test_${DateTime.now().microsecondsSinceEpoch}');
      harness = HiveTestHarness(tempDir);
      await harness.init();
      await harness.openAllBoxes();
      backend = FakeProPurchaseBackend();
      stores = [];
      PurchaseBase.restoreTriggeredExplicitly = false;
    });

    tearDown(() async {
      for (final store in stores) {
        store.dispose();
      }
      await backend.close();
      await harness.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('init configures the backend and mirrors an active entitlement '
        'into BoughtPro (no cold-start restore — RC recovers reinstalls)',
        () async {
      backend.entitlement = true;
      final store = newStore()..init();

      await until(() => backend.fetchEntitlementCalls > 0);

      expect(backend.initCalls, 1);
      expect(backend.restoreCalls, 0);
      expect(
        settingsBox().get(SettingsKeys.ProColdStartRestoreDone.name,
            defaultValue: false),
        isFalse,
      );
      await until(() => store.isPro);
      expect(settingsBox().get(SettingsKeys.BoughtPro.name), isTrue);
    });

    test('inactive entitlement mirrors false (lapsed subscription revokes '
        'isPro even when the flag was stale-true)', () async {
      /// Stale mirror from a previous session — the RC fetch must
      /// overwrite it.
      settingsBox().put(SettingsKeys.BoughtPro.name, true);
      backend.entitlement = false;
      final store = newStore()..init();

      await until(() => backend.fetchEntitlementCalls > 0);
      await until(() =>
          settingsBox().get(SettingsKeys.BoughtPro.name) == false);

      expect(store.isPro, isFalse);
    });

    test('entitlement stream updates re-mirror (renewal/lapse mid-session)',
        () async {
      backend.entitlement = false;
      final store = newStore()..init();
      await until(() => backend.fetchEntitlementCalls > 0);
      expect(store.isPro, isFalse);

      backend.entitlement = true;
      backend.entitlementController.add(true);
      await until(() => store.isPro);

      expect(settingsBox().get(SettingsKeys.BoughtPro.name), isTrue);
    });

    test('entitlement fetch error keeps the last mirrored state', () async {
      settingsBox().put(SettingsKeys.BoughtPro.name, true);
      backend.entitlementError = StateError('offline, no cache yet');
      final store = newStore()..init();

      await until(() => backend.fetchEntitlementCalls > 0);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      /// The stale-true mirror survives — graceful degradation, no crash.
      expect(store.isPro, isTrue);
    });

    test('successful buy mirrors the entitlement immediately', () async {
      backend.entitlement = false;
      final store = newStore()..init();
      await until(() => backend.fetchEntitlementCalls > 0);

      backend.buyResult = true;
      final bought = await store.buy(fakeProProduct(kProYearlyId));

      expect(bought, isTrue);
      expect(store.isPro, isTrue);
      expect(settingsBox().get(SettingsKeys.BoughtPro.name), isTrue);
    });

    test('explicit restore with an active entitlement sets BoughtPro and '
        'arms/disarms the dialog flag (RC has no purchase-stream event)',
        () async {
      backend.entitlement = false;
      final store = newStore()..init();
      await until(() => backend.fetchEntitlementCalls > 0);

      backend.restoreResult = true;
      await store.restore(explicit: true);

      expect(backend.restoreCalls, 1);
      expect(store.isPro, isTrue);
      expect(PurchaseBase.restoreTriggeredExplicitly, isFalse);
    });

    test('restore error disarms the dialog flag and records lastError',
        () async {
      backend.entitlement = false;
      final store = newStore()..init();
      await until(() => backend.fetchEntitlementCalls > 0);

      backend.restoreError = StateError('restore failed');
      await store.restore(explicit: true);

      expect(PurchaseBase.restoreTriggeredExplicitly, isFalse);
      expect(store.lastError, contains('restore failed'));
    });
  });
}
