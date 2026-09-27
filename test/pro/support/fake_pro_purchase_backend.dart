import 'dart:async';

import 'package:obs_blade/utils/pro_plan.dart';
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

  /// What [fetchProPlan] reports; null = backend can't tell.
  ProPlanState? proPlan;

  final StreamController<ProPlanState> planController =
      StreamController<ProPlanState>.broadcast();

  /// The replaced subscription each [buy] was asked for (null = none).
  final List<String?> buyReplacing = [];

  @override
  Future<ProPlanState?> fetchProPlan({bool fresh = false}) async {
    this.freshPlanFetches += fresh ? 1 : 0;
    return this.proPlan;
  }

  /// How often [fetchProPlan] was asked to skip the cache
  int freshPlanFetches = 0;

  @override
  Stream<ProPlanState> get proPlanStream => this.planController.stream;

  @override
  Future<bool> buy(
    ProProduct product, {
    String? replacingSubscriptionStoreId,
  }) async {
    this.buyCalls++;
    this.buyReplacing.add(replacingSubscriptionStoreId);
    if (this.buyError != null) throw this.buyError!;
    return this.buyResult;
  }

  @override
  Future<bool> restore() async {
    this.restoreCalls++;
    if (this.restoreError != null) throw this.restoreError!;
    return this.restoreResult;
  }

  Future<void> close() async {
    await this.entitlementController.close();
    await this.planController.close();
  }
}
