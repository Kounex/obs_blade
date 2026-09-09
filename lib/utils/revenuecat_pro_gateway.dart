import 'dart:async';

import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart' hide LogLevel;

import '../models/enums/log_level.dart';
import 'general_helper.dart';
import 'pro_ids.dart';
import 'pro_product.dart';
import 'pro_purchase_backend.dart';
import 'revenuecat_config.dart';

/// RevenueCat `Package` → paywall-facing [ProProduct]. Pure translation
/// (testable without the native SDK — `Package.fromJson` builds the DTO
/// from a plain map); the package rides along in `storeObject` so
/// [RevenueCatProGateway.buy] can purchase it.
ProProduct proProductFromPackage(Package package) => ProProduct(
  id: package.storeProduct.identifier,
  title: package.storeProduct.title,
  priceString: package.storeProduct.priceString,
  subscriptionPeriod: package.storeProduct.subscriptionPeriod,
  storeObject: package,
);

/// Entitlement truth: the `pro` entitlement being active in a
/// [CustomerInfo] snapshot. RevenueCat tracks expiry/renewal server-side,
/// which closes the legacy path's lapsed-subscription blind spot.
bool proEntitlementActive(CustomerInfo info) =>
    info.entitlements.active.containsKey(kProEntitlementId);

/// [ProPurchaseBackend] over RevenueCat (`purchases_flutter`). Only
/// selected when [revenueCatConfigured] — see `revenuecat_config.dart`.
/// Every SDK call degrades gracefully (throws to `ProStore`, which logs
/// and falls back to the paywall's placeholder states); nothing here
/// crashes on missing offerings/products.
class RevenueCatProGateway implements ProPurchaseBackend {
  final StreamController<bool> _entitlementController =
      StreamController<bool>.broadcast();

  bool _configured = false;

  /// `Purchases.configure` with the platform key + CustomerInfo listener.
  /// Idempotent and self-healing: a failed configure (offline at cold
  /// start) logs and leaves the gateway unconfigured so the next
  /// [init] retries.
  @override
  Future<void> init() async {
    if (this._configured) return;
    final String? apiKey = revenueCatApiKey;
    if (apiKey == null) return;

    try {
      await Purchases.configure(PurchasesConfiguration(apiKey));
      Purchases.addCustomerInfoUpdateListener(
        (CustomerInfo info) =>
            this._entitlementController.add(proEntitlementActive(info)),
      );
      this._configured = true;
    } catch (e) {
      GeneralHelper.advLog(
        'RevenueCat configure failed — $e',
        includeInLogs: true,
        level: LogLevel.Error,
      );
    }
  }

  @override
  bool get handlesEntitlement => true;

  @override
  Stream<bool> get proEntitlementStream => this._entitlementController.stream;

  /// RevenueCat caches CustomerInfo on-device, so this also answers
  /// offline (stale-but-recent truth) — the basis for the fast-boot /
  /// offline entitlement mirror.
  @override
  Future<bool> fetchProEntitlement() async =>
      proEntitlementActive(await Purchases.getCustomerInfo());

  /// No dedicated "availability" probe in the SDK — an offerings fetch is
  /// the closest equivalent (also warms the cache the paywall reads next).
  @override
  Future<bool> isStoreAvailable() async {
    try {
      await Purchases.getOfferings();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Pro packages of the current offering, keyed by their STORE product
  /// id (packages get dashboard-side identifiers like `$rc_annual`, so
  /// matching rides `storeProduct.identifier`). No current offering or
  /// unlinked products → empty, the paywall's placeholder state.
  @override
  Future<List<ProProduct>> queryProProducts() async {
    final Offering? current = (await Purchases.getOfferings()).current;
    if (current == null) return [];
    return current.availablePackages
        .where((package) => isProProductId(package.storeProduct.identifier))
        .map(proProductFromPackage)
        .toList();
  }

  /// User cancellation is a normal outcome, not an error — swallow it to
  /// `false` so the paywall doesn't surface an error for it.
  @override
  Future<bool> buy(ProProduct product) async {
    try {
      final PurchaseResult result = await Purchases.purchase(
        PurchaseParams.package(product.storeObject! as Package),
      );
      return proEntitlementActive(result.customerInfo);
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        return false;
      }
      rethrow;
    }
  }

  /// RC-side restore: reinstalls/cross-device recoveries resolve through
  /// RevenueCat's receipt sync, replacing the legacy once-per-install
  /// cold-start restore. Returns whether the entitlement came back active
  /// (drives the explicit-restore dialog in `ProStore`).
  @override
  Future<bool> restore() async =>
      proEntitlementActive(await Purchases.restorePurchases());

  Future<void> dispose() => this._entitlementController.close();
}
