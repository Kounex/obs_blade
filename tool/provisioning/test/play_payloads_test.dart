import 'package:provisioning/src/money.dart';
import 'package:provisioning/src/play_payloads.dart';
import 'package:test/test.dart';

void main() {
  group('moneyFromDecimal', () {
    test('splits dollars and cents into units/nanos', () {
      expect(moneyFromDecimal('24.99'),
          {'currencyCode': 'USD', 'units': '24', 'nanos': 990000000});
      expect(moneyFromDecimal('79.99'),
          {'currencyCode': 'USD', 'units': '79', 'nanos': 990000000});
      expect(moneyFromDecimal('5'),
          {'currencyCode': 'USD', 'units': '5', 'nanos': 0});
      expect(moneyFromDecimal('4.5'),
          {'currencyCode': 'USD', 'units': '4', 'nanos': 500000000});
    });

    test('rejects malformed prices', () {
      expect(() => moneyFromDecimal('abc'), throwsFormatException);
      expect(() => moneyFromDecimal('1.999'), throwsFormatException);
      expect(() => moneyFromDecimal(''), throwsFormatException);
    });
  });

  group('normalizePrice', () {
    test('matches ASC customerPrice formatting', () {
      expect(normalizePrice('24.99'), '24.99');
      expect(normalizePrice('25'), '25');
      expect(normalizePrice('4.5'), '4.50');
    });
  });

  group('subscriptionCreate', () {
    test('matches the androidpublisher v3 Subscription resource', () {
      final body = subscriptionCreate(
        packageName: 'com.kounex.obsBlade',
        productId: 'pro',
        title: 'Pro',
        basePlans: const [
          BasePlanSpec(
              basePlanId: 'pro-yearly',
              billingPeriodDuration: 'P1Y',
              priceUsd: '24.99'),
          BasePlanSpec(
              basePlanId: 'pro-monthly',
              billingPeriodDuration: 'P1M',
              priceUsd: '4.99'),
        ],
      );
      expect(body['packageName'], 'com.kounex.obsBlade');
      expect(body['productId'], 'pro');
      final listings = body['listings'] as List;
      // en-GB first: Play requires a listing in the app's default language.
      expect(listings.map((l) => (l as Map)['languageCode']),
          ['en-GB', 'en-US']);
      final plans = body['basePlans'] as List;
      expect(plans, hasLength(2));
      final yearly = plans.first as Map;
      expect(yearly['basePlanId'], 'pro-yearly');
      expect(
          (yearly['autoRenewingBasePlanType']
              as Map)['billingPeriodDuration'],
          'P1Y');
      final region =
          ((yearly['regionalConfigs'] as List).single as Map);
      expect(region['regionCode'], 'US');
      expect(region['newSubscriberAvailability'], true);
      expect((region['price'] as Map)['units'], '24');
      expect((region['price'] as Map)['nanos'], 990000000);
    });
  });

  group('subscriptionPatch', () {
    test('carries existing base plans, appends missing, omits listings', () {
      final existing = [
        {'basePlanId': 'pro-yearly', 'state': 'ACTIVE'}
      ];
      final body = subscriptionPatch(
        existingBasePlans: existing,
        missing: const [
          BasePlanSpec(
              basePlanId: 'pro-monthly',
              billingPeriodDuration: 'P1M',
              priceUsd: '4.99'),
        ],
      );
      final plans = body['basePlans'] as List;
      expect(plans, hasLength(2));
      expect((plans.first as Map)['basePlanId'], 'pro-yearly');
      expect((plans.last as Map)['basePlanId'], 'pro-monthly');
      expect(body.containsKey('listings'), isFalse,
          reason: 'resume PATCH must not clobber console-customized '
              'listing text');
    });
  });

  group('oneTimeProductUpsert', () {
    test('matches the batchUpdate shape with allowMissing', () {
      final body = oneTimeProductUpsert(
        packageName: 'com.kounex.obsBlade',
        productId: 'pro_lifetime',
        purchaseOptionId: 'pro-lifetime',
        title: 'Pro — Lifetime',
        priceUsd: '79.99',
      );
      final request = (body['requests'] as List).single as Map;
      expect(request['allowMissing'], true);
      expect(request['updateMask'], 'listings,purchaseOptions');
      expect((request['regionsVersion'] as Map)['version'], '2022/02');
      final product = request['oneTimeProduct'] as Map;
      expect(product['productId'], 'pro_lifetime');
      final option =
          (product['purchaseOptions'] as List).single as Map;
      expect(option['purchaseOptionId'], 'pro-lifetime');
      expect((option['buyOption'] as Map)['legacyCompatible'], true);
      final regional =
          (option['regionalPricingAndAvailabilityConfigs'] as List).single
              as Map;
      expect(regional['availability'], 'AVAILABLE');
      expect((regional['price'] as Map)['units'], '79');
    });
  });

  group('activatePurchaseOption', () {
    test('matches BatchUpdatePurchaseOptionStatesRequest', () {
      final body = activatePurchaseOption(
        packageName: 'com.kounex.obsBlade',
        productId: 'pro_lifetime',
        purchaseOptionId: 'pro-lifetime',
      );
      final request = (body['requests'] as List).single as Map;
      final activate = request['activatePurchaseOptionRequest'] as Map;
      expect(activate['purchaseOptionId'], 'pro-lifetime');
      expect(activate['productId'], 'pro_lifetime');
      expect(activate['packageName'], 'com.kounex.obsBlade');
    });
  });
}
