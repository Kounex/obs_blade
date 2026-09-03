import 'package:in_app_purchase/in_app_purchase.dart';

import 'pro_ids.dart';

/// Seam over the `InAppPurchase` singleton — `InAppPurchase` itself can't
/// be constructed/injected, so store-facing calls go through this gateway
/// which tests replace with a fake.
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
  Future<ProductDetailsResponse> queryProductDetails(
          Set<String> identifiers) =>
      InAppPurchase.instance.queryProductDetails(identifiers);

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) =>
      InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);

  @override
  Future<void> restorePurchases() => InAppPurchase.instance.restorePurchases();
}

/// Thin wrapper around the store for everything Pro — injectable so
/// `ProStore` stays unit-testable without platform fakes. Every method may
/// legitimately see "nothing" (products don't exist store-side yet, store
/// unavailable on desktop/web) — callers degrade gracefully instead of
/// treating that as an error.
class ProPurchaseService {
  final ProPurchaseGateway _gateway;

  ProPurchaseService({ProPurchaseGateway? gateway})
      : this._gateway = gateway ?? InAppPurchaseGateway();

  /// Purchase event stream (shared with [PurchaseBase], which owns the
  /// entitlement-flag writes).
  Stream<List<PurchaseDetails>> get purchaseStream =>
      this._gateway.purchaseStream;

  Future<bool> isStoreAvailable() => this._gateway.isAvailable();

  /// Live [ProductDetails] for the pro ids — empty while the products
  /// don't exist store-side; `notFoundIDs` is expected, not an error.
  Future<List<ProductDetails>> queryProProducts() async =>
      (await this._gateway.queryProductDetails(kProProductIds)).productDetails;

  /// Both the subscriptions and the lifetime buy-out go through
  /// `buyNonConsumable` (the plugin's documented path for subscriptions on
  /// iOS/Android).
  Future<bool> buy(ProductDetails product) => this._gateway.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );

  /// Restored purchases arrive on [purchaseStream] with
  /// `PurchaseStatus.restored` — the explicit-vs-silent distinction (dialog
  /// or not) is handled by the flag in `PurchaseBase`, not here.
  Future<void> restore() => this._gateway.restorePurchases();
}
