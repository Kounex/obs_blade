import 'dart:async';

import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart' hide LogLevel;

import '../models/enums/log_level.dart';
import 'general_helper.dart';
import 'pro_ids.dart';
import 'pro_plan.dart';
import 'pro_product.dart';
import 'pro_purchase_backend.dart';
import 'revenuecat_config.dart';

/// RevenueCat `Package` → paywall-facing [ProProduct]. Pure translation
/// (testable without the native SDK — `Package.fromJson` builds the DTO
/// from a plain map); the package rides along in `storeObject` so
/// [RevenueCatProGateway.buy] can purchase it.
///
/// The id is the app's plan id ([canonicalProProductId]): Play reports
/// subscriptions as `pro:pro-yearly`, which the paywall must still match
/// to its yearly offer.
ProProduct proProductFromPackage(Package package) => ProProduct(
  id:
      canonicalProProductId(package.storeProduct.identifier) ??
      package.storeProduct.identifier,
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

/// The user's plan from a [CustomerInfo] snapshot: active Pro
/// subscriptions (with their renewal state) and whether the lifetime
/// product was bought.
ProPlanState proPlanFromCustomerInfo(CustomerInfo info) => proPlanFrom(
  activeSubscriptions: info.activeSubscriptions.map(
    (String storeId) => (
      storeId: storeId,
      willRenew:
          info.subscriptionsByProductIdentifier[storeId]?.willRenew ??
          _entitlementWillRenew(info, storeId),
    ),
  ),
  ownsLifetime: info.nonSubscriptionTransactions.any(
    (t) => canonicalProProductId(t.productIdentifier) == kProLifetimeId,
  ),
);

/// Fallback when RevenueCat has no per-subscription entry: the `pro`
/// entitlement's renewal flag, if that subscription backs it.
bool _entitlementWillRenew(CustomerInfo info, String storeId) {
  final EntitlementInfo? pro = info.entitlements.active[kProEntitlementId];
  if (pro == null) return false;
  final String? backing = canonicalProProductId(
    pro.productIdentifier,
    planIdentifier: pro.productPlanIdentifier,
  );
  return backing != null &&
      backing == canonicalProProductId(storeId) &&
      pro.willRenew;
}

/// [ProPurchaseBackend] over RevenueCat (`purchases_flutter`). Only
/// selected when [revenueCatConfigured] — see `revenuecat_config.dart`.
/// Every SDK call degrades gracefully (throws to `ProStore`, which logs
/// and falls back to the paywall's placeholder states); nothing here
/// crashes on missing offerings/products.
class RevenueCatProGateway implements ProPurchaseBackend {
  final StreamController<bool> _entitlementController =
      StreamController<bool>.broadcast();

  final StreamController<ProPlanState> _planController =
      StreamController<ProPlanState>.broadcast();

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
      Purchases.addCustomerInfoUpdateListener((CustomerInfo info) {
        this._entitlementController.add(proEntitlementActive(info));
        this._planController.add(proPlanFromCustomerInfo(info));
      });
      this._configured = true;
    } catch (e) {
      GeneralHelper.advLog(
        'RevenueCat configure failed - $e',
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

  @override
  Stream<ProPlanState> get proPlanStream => this._planController.stream;

  @override
  Future<ProPlanState?> fetchProPlan({bool fresh = false}) async {
    if (fresh) await Purchases.invalidateCustomerInfoCache();
    return proPlanFromCustomerInfo(await Purchases.getCustomerInfo());
  }

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
        .where(
          (package) =>
              canonicalProProductId(package.storeProduct.identifier) != null,
        )
        .map(proProductFromPackage)
        .toList();
  }

  /// User cancellation is a normal outcome, not an error — swallow it to
  /// `false` so the paywall doesn't surface an error for it.
  @override
  Future<bool> buy(
    ProProduct product, {
    String? replacingSubscriptionStoreId,
  }) async {
    try {
      final PurchaseResult result = await Purchases.purchase(
        PurchaseParams.package(
          product.storeObject! as Package,

          /// Play: change the running subscription (named by its product
          /// id, without the base plan) instead of adding a second one,
          /// crediting the unused time. Ignored on the App Store, which
          /// switches within the subscription group itself.
          productChangeInfo: replacingSubscriptionStoreId == null
              ? null
              : StoreProductChangeInfo(
                  replacingSubscriptionStoreId.split(':').first,
                  replacementMode: StoreReplacementMode.withTimeProration,
                ),
        ),
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

  Future<void> dispose() async {
    await this._entitlementController.close();
    await this._planController.close();
  }
}
