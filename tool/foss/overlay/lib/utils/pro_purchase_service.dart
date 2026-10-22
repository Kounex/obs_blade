import 'pro_plan.dart';
import 'pro_product.dart';

/// FOSS build (copied over `lib/utils/pro_purchase_service.dart` by
/// `tool/foss/prepare.sh`): no store, no products, no entitlement. Same
/// surface as the store version so `ProStore` compiles unchanged - which
/// never calls it anyway, `kFoss` stops it in `ProStore.init`.
class ProPurchaseService {
  ProPurchaseService();

  bool get handlesEntitlement => false;

  Stream<bool> get proEntitlementStream => const Stream<bool>.empty();

  Future<bool?> fetchProEntitlement() async => null;

  Future<void> init() async {}

  Future<bool> isStoreAvailable() async => false;

  Future<List<ProProduct>> queryProProducts() async => const [];

  Future<bool> buy(
    ProProduct product, {
    String? replacingSubscriptionStoreId,
  }) async => false;

  Future<ProPlanState?> fetchProPlan({bool fresh = false}) async => null;

  Stream<ProPlanState> get proPlanStream => const Stream.empty();

  Future<bool> restore() async => false;

  Future<void> restoreLegacyPurchases() async {}
}
