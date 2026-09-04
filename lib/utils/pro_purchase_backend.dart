import 'pro_product.dart';

/// Platform-neutral seam behind [ProPurchaseService] — implemented by the
/// legacy direct-`in_app_purchase` path ([InAppPurchaseProBackend]) and by
/// [RevenueCatProGateway]. Everything may legitimately see "nothing"
/// (products don't exist store-side yet, store unreachable, RevenueCat
/// unconfigured) — callers degrade gracefully instead of treating that as
/// an error.
abstract class ProPurchaseBackend {
  /// True when this backend is the entitlement source of truth
  /// (RevenueCat — expiry tracked server-side). False for the legacy
  /// path, where truth is the `BoughtPro` box flag written by
  /// `PurchaseBase` off the purchase stream.
  bool get handlesEntitlement;

  /// Backend setup (RevenueCat: `Purchases.configure` + CustomerInfo
  /// listener). No-op for the legacy path. Fire-and-forget from
  /// `ProStore.init` — must swallow+log its own errors.
  Future<void> init();

  /// Entitlement-active updates (RevenueCat CustomerInfo listener).
  /// The legacy path never emits — its truth rides the settings box.
  Stream<bool> get proEntitlementStream;

  /// Current entitlement state, or null when this backend doesn't know
  /// (legacy path — read the `BoughtPro` box flag instead).
  Future<bool?> fetchProEntitlement();

  Future<bool> isStoreAvailable();

  /// Live products for the paywall — empty while the products don't
  /// exist store-side (the expected state until launch).
  Future<List<ProProduct>> queryProProducts();

  Future<bool> buy(ProProduct product);

  /// Returns true when the restore surfaced an active entitlement
  /// (RevenueCat reports it synchronously via CustomerInfo). The legacy
  /// path always returns false — restored purchases arrive on the IAP
  /// purchase stream instead, where `PurchaseBase` handles them.
  Future<bool> restore();
}
