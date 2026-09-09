import 'package:in_app_purchase/in_app_purchase.dart';

import 'pro_ids.dart';
import 'pro_product.dart';
import 'pro_purchase_backend.dart';
import 'revenuecat_config.dart';
import 'revenuecat_pro_gateway.dart';

/// Seam over the `InAppPurchase` singleton — `InAppPurchase` itself can't
/// be constructed/injected, so store-facing calls go through this gateway
/// which tests replace with a fake. This is the LEGACY (direct-IAP) pro
/// path; it also keeps serving tips/blacksmith via `PurchaseBase`.
abstract class ProPurchaseGateway {
  Stream<List<PurchaseDetails>> get purchaseStream;
  Future<bool> isAvailable();
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers);
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam});
  Future<void> restorePurchases();
}

class InAppPurchaseGateway implements ProPurchaseGateway {
  @override
  Stream<List<PurchaseDetails>> get purchaseStream =>
      InAppPurchase.instance.purchaseStream;

  @override
  Future<bool> isAvailable() => InAppPurchase.instance.isAvailable();

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) =>
      InAppPurchase.instance.queryProductDetails(identifiers);

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) =>
      InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);

  @override
  Future<void> restorePurchases() => InAppPurchase.instance.restorePurchases();
}

/// [ProPurchaseBackend] over the direct-IAP gateway. Entitlement truth
/// stays the `BoughtPro` box flag ([handlesEntitlement] is false): the
/// purchase stream events handled by `PurchaseBase` write it, and the
/// once-per-install cold-start restore in `ProStore` covers reinstalls.
/// Lapsed subscriptions are NOT enforceable here (documented blind spot)
/// — the RevenueCat path fixes exactly that.
class InAppPurchaseProBackend implements ProPurchaseBackend {
  final ProPurchaseGateway gateway;

  InAppPurchaseProBackend({ProPurchaseGateway? gateway})
    : this.gateway = gateway ?? InAppPurchaseGateway();

  /// Raw [ProductDetails] → paywall-facing [ProProduct]. IAP's
  /// `ProductDetails` doesn't expose the subscription period portably
  /// (platform extras only), so it stays null on this path — the paywall
  /// hardcodes its cadence copy anyway.
  static ProProduct proProductFromDetails(ProductDetails details) => ProProduct(
    id: details.id,
    title: details.title,
    priceString: details.price,
    storeObject: details,
  );

  @override
  bool get handlesEntitlement => false;

  @override
  Future<void> init() async {}

  @override
  Stream<bool> get proEntitlementStream => const Stream<bool>.empty();

  @override
  Future<bool?> fetchProEntitlement() async => null;

  @override
  Future<bool> isStoreAvailable() => this.gateway.isAvailable();

  /// Live products for the pro ids — empty while the products don't
  /// exist store-side; `notFoundIDs` is expected, not an error.
  @override
  Future<List<ProProduct>> queryProProducts() async =>
      (await this.gateway.queryProductDetails(
        kProProductIds,
      )).productDetails.map(proProductFromDetails).toList();

  /// Both the subscriptions and the lifetime buy-out go through
  /// `buyNonConsumable` (the plugin's documented path for subscriptions on
  /// iOS/Android).
  @override
  Future<bool> buy(ProProduct product) => this.gateway.buyNonConsumable(
    purchaseParam: PurchaseParam(
      productDetails: product.storeObject! as ProductDetails,
    ),
  );

  /// Restored purchases arrive on the purchase stream with
  /// `PurchaseStatus.restored` — the explicit-vs-silent distinction
  /// (dialog or not) is handled by the flag in `PurchaseBase`, not here.
  @override
  Future<bool> restore() async {
    await this.gateway.restorePurchases();
    return false;
  }
}

/// Thin wrapper over the active pro purchase backend so `ProStore` stays
/// unit-testable without platform fakes. Selection: an explicitly
/// injected gateway/backend wins (tests); otherwise RevenueCat when
/// configured ([revenueCatConfigured] — the maintainer drops the API keys
/// into `revenuecat_config.dart`), falling back to direct IAP while the
/// keys are empty.
class ProPurchaseService {
  final ProPurchaseBackend _backend;

  /// Direct-IAP gateway kept alongside a RevenueCat backend: blacksmith
  /// (no longer sold, restore-only for legacy buyers) restores arrive on
  /// the plugin's purchase stream, not in RC's CustomerInfo, so the
  /// paywall's explicit restore also fires [restoreLegacyPurchases].
  final ProPurchaseGateway _legacyGateway;

  ProPurchaseService({
    ProPurchaseGateway? gateway,
    ProPurchaseBackend? backend,
    ProPurchaseGateway? legacyGateway,
  }) : this._legacyGateway = legacyGateway ?? gateway ?? InAppPurchaseGateway(),
       this._backend =
           backend ??
           (gateway != null
               ? InAppPurchaseProBackend(gateway: gateway)
               : revenueCatConfigured
               ? RevenueCatProGateway()
               : InAppPurchaseProBackend());

  /// True when the entitlement comes from this service (RevenueCat
  /// CustomerInfo) rather than the `BoughtPro` box flag / purchase
  /// stream. `ProStore.init` branches on it (no cold-start restore — RC
  /// recovers reinstalls itself via its CustomerInfo cache + restore).
  bool get handlesEntitlement => this._backend.handlesEntitlement;

  /// Purchase event stream of the legacy IAP path (kept for tests /
  /// debugging; `PurchaseBase` listens to `InAppPurchase` directly).
  /// Null on the RevenueCat path, which reports via CustomerInfo instead.
  Stream<List<PurchaseDetails>>? get purchaseStream {
    final ProPurchaseBackend backend = this._backend;
    return backend is InAppPurchaseProBackend
        ? backend.gateway.purchaseStream
        : null;
  }

  Stream<bool> get proEntitlementStream => this._backend.proEntitlementStream;

  Future<bool?> fetchProEntitlement() => this._backend.fetchProEntitlement();

  /// Backend setup — call once, fire-and-forget, from `ProStore.init`.
  Future<void> init() => this._backend.init();

  Future<bool> isStoreAvailable() => this._backend.isStoreAvailable();

  /// Live [ProProduct]s for the paywall — empty while the products
  /// don't exist store-side; graceful by contract, never throws for
  /// "nothing found".
  Future<List<ProProduct>> queryProProducts() =>
      this._backend.queryProProducts();

  Future<bool> buy(ProProduct product) => this._backend.buy(product);

  /// True when the restore surfaced an active entitlement (RevenueCat
  /// only — the legacy path reports via the purchase stream).
  Future<bool> restore() => this._backend.restore();

  /// Restore on the direct IAP plugin stream — blacksmith (restore-only
  /// legacy product) restores arrive there for [PurchaseBase] to pick up,
  /// independent of which backend handles the pro entitlement. Fired
  /// alongside the RevenueCat restore from the paywall so legacy
  /// blacksmith buyers can still recover their themes on a new device.
  Future<void> restoreLegacyPurchases() =>
      this._legacyGateway.restorePurchases();
}
