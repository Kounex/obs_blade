import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:obs_blade/utils/pro_ids.dart';
import 'package:obs_blade/utils/pro_purchase_service.dart';

import 'support/fake_pro_purchase_gateway.dart';

void main() {
  late FakeProPurchaseGateway gateway;
  late ProPurchaseService service;

  setUp(() {
    gateway = FakeProPurchaseGateway();
    service = ProPurchaseService(gateway: gateway);
  });

  tearDown(() => gateway.close());

  test('isStoreAvailable delegates to the gateway', () async {
    expect(await service.isStoreAvailable(), isTrue);

    gateway.available = false;
    expect(await service.isStoreAvailable(), isFalse);
    expect(gateway.isAvailableCalls, 2);
  });

  test('queryProProducts returns only found products (notFoundIDs expected)',
      () async {
    gateway.storeProducts = [fakeProduct(kProYearlyId)];

    final products = await service.queryProProducts();

    expect(products.map((product) => product.id), [kProYearlyId]);
    expect(gateway.queryCalls, 1);
  });

  test('queryProProducts with nothing store-side → empty, no throw', () async {
    final products = await service.queryProProducts();

    expect(products, isEmpty);
  });

  test('buy wraps the product in a PurchaseParam (non-consumable path)',
      () async {
    expect(await service.buy(fakeProProduct(kProLifetimeId)), isTrue);
    expect(gateway.buyCalls, 1);
    expect(gateway.lastBoughtProduct?.id, kProLifetimeId);
  });

  test('restore delegates and propagates errors', () async {
    await service.restore();
    expect(gateway.restoreCalls, 1);

    gateway.restoreError = StateError('nope');
    expect(service.restore(), throwsA(isA<StateError>()));
    await until(() => gateway.restoreCalls == 2);
  });

  test('purchaseStream is exposed from the gateway', () async {
    final events = <List<PurchaseDetails>>[];
    final sub = service.purchaseStream!.listen(events.add);

    gateway.purchaseController
        .add([fakePurchase(kProYearlyId, PurchaseStatus.purchased)]);
    await until(() => events.isNotEmpty);

    expect(events.single.single.productID, kProYearlyId);
    await sub.cancel();
  });
}
