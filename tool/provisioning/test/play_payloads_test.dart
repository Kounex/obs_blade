import 'package:provisioning/src/money.dart';
import 'package:provisioning/src/play_payloads.dart';
import 'package:test/test.dart';

void main() {
  group('moneyFromDecimal', () {
    test('splits dollars and cents into units/nanos', () {
      expect(moneyFromDecimal('24.99'), {
        'currencyCode': 'USD',
        'units': '24',
        'nanos': 990000000,
      });
      expect(moneyFromDecimal('79.99'), {
        'currencyCode': 'USD',
        'units': '79',
        'nanos': 990000000,
      });
      expect(moneyFromDecimal('5'), {
        'currencyCode': 'USD',
        'units': '5',
        'nanos': 0,
      });
      expect(moneyFromDecimal('4.5'), {
        'currencyCode': 'USD',
        'units': '4',
        'nanos': 500000000,
      });
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
      final prices = {
        'US': moneyFromDecimal('24.99'),
        'DE': moneyFromDecimal('24.99', currencyCode: 'EUR'),
      };
      final body = subscriptionCreate(
        packageName: 'com.kounex.obsBlade',
        productId: 'pro',
        title: 'Pro',
        basePlans: const [
          BasePlanSpec(
            basePlanId: 'pro-yearly',
            billingPeriodDuration: 'P1Y',
            priceUsd: '24.99',
          ),
          BasePlanSpec(
            basePlanId: 'pro-monthly',
            billingPeriodDuration: 'P1M',
            priceUsd: '4.99',
          ),
        ],
        pricesByPlan: {'pro-yearly': prices, 'pro-monthly': prices},
      );
      expect(body['packageName'], 'com.kounex.obsBlade');
      expect(body['productId'], 'pro');
      final listings = body['listings'] as List;
      // en-GB first: Play requires a listing in the app's default language.
      expect(listings.map((l) => (l as Map)['languageCode']), [
        'en-GB',
        'en-US',
      ]);
      final plans = body['basePlans'] as List;
      expect(plans, hasLength(2));
      final yearly = plans.first as Map;
      expect(yearly['basePlanId'], 'pro-yearly');
      expect(
        (yearly['autoRenewingBasePlanType'] as Map)['billingPeriodDuration'],
        'P1Y',
      );
      // Region configs are sorted by region code for determinism.
      final regions = (yearly['regionalConfigs'] as List).cast<Map>();
      expect(regions.map((r) => r['regionCode']), ['DE', 'US']);
      expect(regions.first['newSubscriberAvailability'], true);
      expect((regions.first['price'] as Map)['currencyCode'], 'EUR');
      expect((regions.last['price'] as Map)['units'], '24');
      expect((regions.last['price'] as Map)['nanos'], 990000000);
    });
  });

  group('subscriptionPatch', () {
    test('carries existing base plans, appends missing, omits listings', () {
      final existing = [
        {'basePlanId': 'pro-yearly', 'state': 'ACTIVE'},
      ];
      final body = subscriptionPatch(
        existingBasePlans: existing,
        missing: const [
          BasePlanSpec(
            basePlanId: 'pro-monthly',
            billingPeriodDuration: 'P1M',
            priceUsd: '4.99',
          ),
        ],
        pricesByPlan: {
          'pro-monthly': {'US': moneyFromDecimal('4.99')},
        },
      );
      final plans = body['basePlans'] as List;
      expect(plans, hasLength(2));
      expect((plans.first as Map)['basePlanId'], 'pro-yearly');
      expect((plans.last as Map)['basePlanId'], 'pro-monthly');
      expect(
        body.containsKey('listings'),
        isFalse,
        reason:
            'resume PATCH must not clobber console-customized '
            'listing text',
      );
    });
  });

  group('regionPricesMatch', () {
    final wanted = {
      'US': moneyFromDecimal('4.99'),
      'DE': moneyFromDecimal('4.99', currencyCode: 'EUR'),
    };
    final configs = [
      {
        'regionCode': 'DE',
        'price': {'currencyCode': 'EUR', 'units': '4', 'nanos': 990000000},
      },
      {
        'regionCode': 'US',
        'price': {'currencyCode': 'USD', 'units': '4', 'nanos': 990000000},
      },
    ];

    test('true when every wanted region matches (extras ignored)', () {
      expect(regionPricesMatch(configs, wanted), isTrue);
      expect(
        regionPricesMatch([
          ...configs,
          {
            'regionCode': 'JP',
            'price': {'currencyCode': 'JPY', 'units': '800'},
          },
        ], wanted),
        isTrue,
      );
    });

    test('false on missing region, drifted price or drifted currency', () {
      expect(regionPricesMatch([configs.first], wanted), isFalse);
      expect(
        regionPricesMatch([
          configs.first,
          {
            'regionCode': 'US',
            'price': {'currencyCode': 'USD', 'units': '5', 'nanos': 0},
          },
        ], wanted),
        isFalse,
      );
      expect(
        regionPricesMatch([
          configs.first,
          {
            'regionCode': 'US',
            'price': {'currencyCode': 'EUR', 'units': '4', 'nanos': 990000000},
          },
        ], wanted),
        isFalse,
      );
    });
  });

  group('oneTimeProductUpsert', () {
    test('matches the batchUpdate shape with allowMissing', () {
      final body = oneTimeProductUpsert(
        packageName: 'com.kounex.obsBlade',
        productId: 'pro_lifetime',
        purchaseOptionId: 'pro-lifetime',
        title: 'Pro - Lifetime',
        prices: {
          'US': moneyFromDecimal('79.99'),
          'JP': {'currencyCode': 'JPY', 'units': '2600', 'nanos': 0},
        },
      );
      final request = (body['requests'] as List).single as Map;
      expect(request['allowMissing'], true);
      expect(request['updateMask'], 'listings,purchaseOptions');
      expect((request['regionsVersion'] as Map)['version'], '2022/02');
      final product = request['oneTimeProduct'] as Map;
      expect(product['productId'], 'pro_lifetime');
      final option = (product['purchaseOptions'] as List).single as Map;
      expect(option['purchaseOptionId'], 'pro-lifetime');
      expect((option['buyOption'] as Map)['legacyCompatible'], true);
      final regional = (option['regionalPricingAndAvailabilityConfigs'] as List)
          .cast<Map>();
      expect(regional.map((r) => r['regionCode']), ['JP', 'US']);
      expect(regional.first['availability'], 'AVAILABLE');
      expect((regional.last['price'] as Map)['units'], '79');
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
