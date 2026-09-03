import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:obs_blade/utils/pro_purchase_service.dart';

/// Fake [ProPurchaseGateway] — counters record every call (including
/// failed attempts, so tests can assert a throwing call still happened).
class FakeProPurchaseGateway implements ProPurchaseGateway {
  final StreamController<List<PurchaseDetails>> purchaseController =
      StreamController<List<PurchaseDetails>>.broadcast();

  bool available = true;
  List<ProductDetails> storeProducts = [];

  Object? isAvailableError;
  Object? queryError;
  Object? buyError;
  Object? restoreError;

  int isAvailableCalls = 0;
  int queryCalls = 0;
  int buyCalls = 0;
  int restoreCalls = 0;

  ProductDetails? lastBoughtProduct;
  bool buyResult = true;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream =>
      this.purchaseController.stream;

  @override
  Future<bool> isAvailable() async {
    this.isAvailableCalls++;
    if (this.isAvailableError != null) throw this.isAvailableError!;
    return this.available;
  }

  @override
  Future<ProductDetailsResponse> queryProductDetails(
      Set<String> identifiers) async {
    this.queryCalls++;
    if (this.queryError != null) throw this.queryError!;
    final found = this
        .storeProducts
        .where((product) => identifiers.contains(product.id))
        .toList();
    return ProductDetailsResponse(
      productDetails: found,
      notFoundIDs: identifiers
          .difference(found.map((product) => product.id).toSet())
          .toList(),
    );
  }

  @override
  Future<bool> buyNonConsumable(
      {required PurchaseParam purchaseParam}) async {
    this.buyCalls++;
    if (this.buyError != null) throw this.buyError!;
    this.lastBoughtProduct = purchaseParam.productDetails;
    return this.buyResult;
  }

  @override
  Future<void> restorePurchases() async {
    this.restoreCalls++;
    if (this.restoreError != null) throw this.restoreError!;
  }

  Future<void> close() => this.purchaseController.close();
}

ProductDetails fakeProduct(
  String id, {
  String price = '€9.99',
  double rawPrice = 9.99,
}) =>
    ProductDetails(
      id: id,
      title: 'Pro ($id)',
      description: 'description $id',
      price: price,
      rawPrice: rawPrice,
      currencyCode: 'EUR',
      currencySymbol: '€',
    );

PurchaseDetails fakePurchase(String productId, PurchaseStatus status) =>
    PurchaseDetails(
      productID: productId,
      verificationData: PurchaseVerificationData(
        localVerificationData: 'local',
        serverVerificationData: 'server',
        source: 'test',
      ),
      transactionDate: '1234567890',
      status: status,
    );

/// Waits until [condition] holds or ~1s passes (async fire-and-forget
/// paths like the cold-start restore progress on the event loop).
Future<void> until(bool Function() condition) async {
  for (var i = 0; i < 1000 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}
