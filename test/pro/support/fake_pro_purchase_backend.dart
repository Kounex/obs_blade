import 'dart:async';

import 'package:obs_blade/utils/pro_product.dart';
import 'package:obs_blade/utils/pro_purchase_backend.dart';

/// Fake [ProPurchaseBackend] in the RevenueCat role ([handlesEntitlement]
/// is true) — no native SDK involved; counters record every call so tests
/// can assert what `ProStore` asked for on the RC path.
class FakeProPurchaseBackend implements ProPurchaseBackend {
  final StreamController<bool> entitlementController =
      StreamController<bool>.broadcast();

  bool available = true;
  List<ProProduct> storeProducts = [];

  /// What [fetchProEntitlement] reports.
  bool? entitlement;

  /// What [restore] reports (restore surfaced an active entitlement).
  bool restoreResult = false;

  bool buyResult = true;

  Object? initError;
  Object? entitlementError;
  Object? queryError;
  Object? buyError;
  Object? restoreError;

  int initCalls = 0;
  int fetchEntitlementCalls = 0;
  int isAvailableCalls = 0;
  int queryCalls = 0;
  int buyCalls = 0;
  int restoreCalls = 0;

  @override
  bool get handlesEntitlement => true;

  @override
  Future<void> init() async {
    this.initCalls++;
    if (this.initError != null) throw this.initError!;
  }

  @override
  Stream<bool> get proEntitlementStream => this.entitlementController.stream;

  @override
  Future<bool?> fetchProEntitlement() async {
    this.fetchEntitlementCalls++;
    if (this.entitlementError != null) throw this.entitlementError!;
    return this.entitlement;
  }

  @override
  Future<bool> isStoreAvailable() async {
    this.isAvailableCalls++;
    return this.available;
  }

  @override
  Future<List<ProProduct>> queryProProducts() async {
    this.queryCalls++;
    if (this.queryError != null) throw this.queryError!;
    return this.storeProducts;
  }

  @override
  Future<bool> buy(ProProduct product) async {
    this.buyCalls++;
    if (this.buyError != null) throw this.buyError!;
    return this.buyResult;
  }

  @override
  Future<bool> restore() async {
    this.restoreCalls++;
    if (this.restoreError != null) throw this.restoreError!;
    return this.restoreResult;
  }

  Future<void> close() => this.entitlementController.close();
}
