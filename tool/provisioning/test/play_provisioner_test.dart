import 'package:provisioning/src/api_client.dart';
import 'package:provisioning/src/money.dart';
import 'package:provisioning/src/play_payloads.dart';
import 'package:provisioning/src/play_provisioner.dart';
import 'package:test/test.dart';

import 'fake_api_client.dart';

const pkg = 'com.kounex.obsBlade';
const basePlans = [
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
];

Map<String, Object?> _subscription(List<Map<String, Object?>> plans) => {
  'productId': 'pro',
  'packageName': pkg,
  'basePlans': plans,
};

/// Google's convertRegionPrices response: US/DE entries get overridden by
/// nominal parity anyway; only the JPY passthrough ([jpUnits]) matters.
void scriptConvertPrices(FakeApiClient client, String jpUnits) => client.on(
  'POST',
  'androidpublisher/v3/applications/$pkg/pricing:convertRegionPrices',
  ApiResponse(200, {
    'regionVersion': {'version': '2025/03'},
    'convertedRegionPrices': {
      'US': {
        'price': {'currencyCode': 'USD', 'units': '9', 'nanos': 990000000},
      },
      'DE': {
        'price': {'currencyCode': 'EUR', 'units': '9', 'nanos': 490000000},
      },
      'JP': {
        'price': {'currencyCode': 'JPY', 'units': jpUnits},
      },
    },
  }),
);

/// The wanted per-region configs for a plan/product at [priceUsd] given the
/// scripted conversion table: EUR + USD at nominal parity, JPY passthrough.
List<Map<String, Object?>> _configs(
  String priceUsd,
  String jpUnits, {
  required bool subscription,
}) => [
  {
    'regionCode': 'DE',
    if (subscription)
      'newSubscriberAvailability': true
    else
      'availability': 'AVAILABLE',
    'price': moneyFromDecimal(priceUsd, currencyCode: 'EUR'),
  },
  {
    'regionCode': 'JP',
    if (subscription)
      'newSubscriberAvailability': true
    else
      'availability': 'AVAILABLE',
    'price': {'currencyCode': 'JPY', 'units': jpUnits, 'nanos': 0},
  },
  {
    'regionCode': 'US',
    if (subscription)
      'newSubscriberAvailability': true
    else
      'availability': 'AVAILABLE',
    'price': moneyFromDecimal(priceUsd),
  },
];

Map<String, Object?> _plan(
  String id,
  String state,
  String priceUsd, {
  String jpUnits = '800',
}) => {
  'basePlanId': id,
  'state': state,
  'regionalConfigs': _configs(priceUsd, jpUnits, subscription: true),
};

Map<String, Object?> _oneTimeProduct(
  String state,
  String priceUsd, {
  String? title,
  String jpUnits = '2600',
}) => {
  'productId': 'pro_lifetime',
  'listings': [
    {'languageCode': 'en-US', 'title': title ?? PlayProvisioner.lifetimeTitle},
  ],
  'purchaseOptions': [
    {
      'purchaseOptionId': 'pro-lifetime',
      'state': state,
      'regionalPricingAndAvailabilityConfigs': _configs(
        priceUsd,
        jpUnits,
        subscription: false,
      ),
    },
  ],
};

void main() {
  group('PlayProvisioner', () {
    test('creates and activates everything when nothing exists', () async {
      final client = FakeApiClient();
      final logs = <String>[];

      // Region price tables: 24.99 (yearly), 4.99 (monthly), 79.99
      // (lifetime) — fetched in that order.
      scriptConvertPrices(client, '800');
      scriptConvertPrices(client, '200');
      scriptConvertPrices(client, '2600');
      // Subscription GET -> 404 (missing); after create the re-read shows
      // the two base plans in DRAFT.
      client.on(
        'GET',
        'androidpublisher/v3/applications/$pkg/subscriptions/pro',
        ApiResponse(404, null),
      );
      client.on(
        'GET',
        'androidpublisher/v3/applications/$pkg/subscriptions/pro',
        ApiResponse(
          200,
          _subscription([
            {'basePlanId': 'pro-yearly', 'state': 'DRAFT'},
            {'basePlanId': 'pro-monthly', 'state': 'DRAFT'},
          ]),
        ),
      );
      // One-time product: GET 404, batchUpdate creates, re-read DRAFT.
      client.on(
        'GET',
        'androidpublisher/v3/applications/$pkg/oneTimeProducts/pro_lifetime',
        ApiResponse(404, null),
      );
      client.on(
        'GET',
        'androidpublisher/v3/applications/$pkg/oneTimeProducts/pro_lifetime',
        ApiResponse(200, {
          'productId': 'pro_lifetime',
          'purchaseOptions': [
            {'purchaseOptionId': 'pro-lifetime', 'state': 'DRAFT'},
          ],
        }),
      );

      final provisioner = PlayProvisioner(
        client: client,
        packageName: pkg,
        log: logs.add,
      );
      final ok = await provisioner.run(
        basePlans: basePlans,
        lifetimePriceUsd: '79.99',
      );

      expect(ok, isTrue);
      expect(
        client.count(
          'POST',
          'androidpublisher/v3/applications/$pkg/subscriptions',
        ),
        1,
      );
      expect(
        client.count(
          'POST',
          'androidpublisher/v3/applications/$pkg/subscriptions/pro/'
              'basePlans/pro-yearly:activate',
        ),
        1,
      );
      expect(
        client.count(
          'POST',
          'androidpublisher/v3/applications/$pkg/subscriptions/pro/'
              'basePlans/pro-monthly:activate',
        ),
        1,
      );
      expect(
        client.count(
          'POST',
          'androidpublisher/v3/applications/$pkg/oneTimeProducts:batchUpdate',
        ),
        1,
      );
      expect(
        client.count(
          'POST',
          'androidpublisher/v3/applications/$pkg/oneTimeProducts/'
              'pro_lifetime/purchaseOptions:batchUpdateStates',
        ),
        1,
      );

      // The created subscription carries the full per-region table:
      // EUR at nominal parity (NOT Google's converted 9.49), JPY as
      // Google's converted passthrough.
      final createBody = client
          .bodiesFor(
            'POST',
            'androidpublisher/v3/applications/$pkg/subscriptions',
          )
          .single;
      final yearlyPlan = (createBody['basePlans'] as List)
          .whereType<Map>()
          .firstWhere((b) => b['basePlanId'] == 'pro-yearly');
      final yearlyConfigs = {
        for (final c
            in (yearlyPlan['regionalConfigs'] as List).whereType<Map>())
          c['regionCode'] as String: c['price'] as Map,
      };
      expect(yearlyConfigs.keys, ['DE', 'JP', 'US']);
      expect(yearlyConfigs['DE'], {
        'currencyCode': 'EUR',
        'units': '24',
        'nanos': 990000000,
      });
      expect(yearlyConfigs['JP'], {
        'currencyCode': 'JPY',
        'units': '800',
        'nanos': 0,
      });
      expect(yearlyConfigs['US'], {
        'currencyCode': 'USD',
        'units': '24',
        'nanos': 990000000,
      });
    });

    test('is a no-op when everything already exists and is active', () async {
      final client = FakeApiClient();
      final logs = <String>[];

      // Region price tables (yearly 24.99, monthly 4.99, lifetime 79.99).
      scriptConvertPrices(client, '800');
      scriptConvertPrices(client, '200');
      scriptConvertPrices(client, '2600');
      // Scripted twice: once for the existence/base-plan check, once for
      // the post-create state re-read.
      for (var i = 0; i < 2; i++) {
        client.on(
          'GET',
          'androidpublisher/v3/applications/$pkg/subscriptions/pro',
          ApiResponse(
            200,
            _subscription([
              _plan('pro-yearly', 'ACTIVE', '24.99'),
              _plan('pro-monthly', 'ACTIVE', '4.99', jpUnits: '200'),
            ]),
          ),
        );
      }
      client.on(
        'GET',
        'androidpublisher/v3/applications/$pkg/oneTimeProducts/pro_lifetime',
        ApiResponse(200, _oneTimeProduct('ACTIVE', '79.99')),
      );

      final provisioner = PlayProvisioner(
        client: client,
        packageName: pkg,
        log: logs.add,
      );
      final ok = await provisioner.run(
        basePlans: basePlans,
        lifetimePriceUsd: '79.99',
      );

      expect(ok, isTrue);
      // No writes — the pricing:convertRegionPrices lookups are read-only
      // POSTs by API design and don't count.
      expect(
        client.requests.where(
          (r) =>
              r.startsWith('POST') &&
              !r.contains('pricing:convertRegionPrices'),
        ),
        isEmpty,
      );
      expect(logs.any((l) => l.contains('already exists')), isTrue);
      expect(logs.any((l) => l.contains('already ACTIVE')), isTrue);
    });

    test(
      'patches in a missing base plan on an existing subscription',
      () async {
        final client = FakeApiClient();
        final logs = <String>[];

        scriptConvertPrices(client, '800');
        scriptConvertPrices(client, '200');
        scriptConvertPrices(client, '2600');
        client.on(
          'GET',
          'androidpublisher/v3/applications/$pkg/subscriptions/pro',
          ApiResponse(
            200,
            _subscription([_plan('pro-yearly', 'ACTIVE', '24.99')]),
          ),
        );
        // Re-read after patch: both plans, monthly still DRAFT.
        client.on(
          'GET',
          'androidpublisher/v3/applications/$pkg/subscriptions/pro',
          ApiResponse(
            200,
            _subscription([
              {'basePlanId': 'pro-yearly', 'state': 'ACTIVE'},
              {'basePlanId': 'pro-monthly', 'state': 'DRAFT'},
            ]),
          ),
        );
        client.on(
          'GET',
          'androidpublisher/v3/applications/$pkg/oneTimeProducts/pro_lifetime',
          ApiResponse(200, _oneTimeProduct('ACTIVE', '79.99')),
        );

        final provisioner = PlayProvisioner(
          client: client,
          packageName: pkg,
          log: logs.add,
        );
        final ok = await provisioner.run(
          basePlans: basePlans,
          lifetimePriceUsd: '79.99',
        );

        expect(ok, isTrue);
        expect(
          client.count(
            'PATCH',
            'androidpublisher/v3/applications/$pkg/subscriptions/pro',
          ),
          1,
        );
        final patchRequest = client.requests.singleWhere(
          (r) => r.startsWith('PATCH '),
        );
        expect(patchRequest, contains('updateMask=basePlans'));
        expect(
          patchRequest,
          isNot(contains('listings')),
          reason:
              'resume PATCH must not touch console-customized '
              'listing text',
        );
        expect(
          client.count(
            'POST',
            'androidpublisher/v3/applications/$pkg/subscriptions/pro/'
                'basePlans/pro-monthly:activate',
          ),
          1,
        );
        expect(
          client.count(
            'POST',
            'androidpublisher/v3/applications/$pkg/subscriptions/pro/'
                'basePlans/pro-yearly:activate',
          ),
          0,
          reason: 'already-active base plan must not be re-activated',
        );
      },
    );
    test('updates prices when they drift from the wanted values', () async {
      final client = FakeApiClient();
      final logs = <String>[];

      // Region price tables for the WANTED prices: yearly 49.99, monthly
      // 4.99, lifetime 99.99.
      scriptConvertPrices(client, '1700');
      scriptConvertPrices(client, '200');
      scriptConvertPrices(client, '3300');
      // Yearly at the old 24.99, monthly already correct; scripted twice
      // (check + activation re-read).
      for (var i = 0; i < 2; i++) {
        client.on(
          'GET',
          'androidpublisher/v3/applications/$pkg/subscriptions/pro',
          ApiResponse(
            200,
            _subscription([
              _plan('pro-yearly', 'ACTIVE', '24.99'),
              _plan('pro-monthly', 'ACTIVE', '4.99', jpUnits: '200'),
            ]),
          ),
        );
      }
      // Lifetime at the old 79.99, then re-read after the update.
      client.on(
        'GET',
        'androidpublisher/v3/applications/$pkg/oneTimeProducts/pro_lifetime',
        ApiResponse(200, _oneTimeProduct('ACTIVE', '79.99')),
      );
      client.on(
        'GET',
        'androidpublisher/v3/applications/$pkg/oneTimeProducts/pro_lifetime',
        ApiResponse(200, _oneTimeProduct('ACTIVE', '99.99', jpUnits: '3300')),
      );

      const updatedPlans = [
        BasePlanSpec(
          basePlanId: 'pro-yearly',
          billingPeriodDuration: 'P1Y',
          priceUsd: '49.99',
        ),
        BasePlanSpec(
          basePlanId: 'pro-monthly',
          billingPeriodDuration: 'P1M',
          priceUsd: '4.99',
        ),
      ];
      final provisioner = PlayProvisioner(
        client: client,
        packageName: pkg,
        log: logs.add,
      );
      final ok = await provisioner.run(
        basePlans: updatedPlans,
        lifetimePriceUsd: '99.99',
      );

      expect(ok, isTrue);
      final patches = client.bodiesFor(
        'PATCH',
        'androidpublisher/v3/applications/$pkg/subscriptions/pro',
      );
      expect(patches, hasLength(1));
      final patchedPlans = patches.first['basePlans'] as List;
      final yearly = patchedPlans.whereType<Map>().firstWhere(
        (b) => b['basePlanId'] == 'pro-yearly',
      );
      final yearlyUs = (yearly['regionalConfigs'] as List)
          .whereType<Map>()
          .firstWhere((c) => c['regionCode'] == 'US');
      expect((yearlyUs['price'] as Map)['units'], '49');
      // …with EUR at nominal parity and JPY as the converted passthrough.
      final yearlyDe = (yearly['regionalConfigs'] as List)
          .whereType<Map>()
          .firstWhere((c) => c['regionCode'] == 'DE');
      expect(yearlyDe['price'], {
        'currencyCode': 'EUR',
        'units': '49',
        'nanos': 990000000,
      });
      final yearlyJp = (yearly['regionalConfigs'] as List)
          .whereType<Map>()
          .firstWhere((c) => c['regionCode'] == 'JP');
      expect(yearlyJp['price'], {
        'currencyCode': 'JPY',
        'units': '1700',
        'nanos': 0,
      });
      // Monthly plan carried over untouched.
      final monthly = patchedPlans.whereType<Map>().firstWhere(
        (b) => b['basePlanId'] == 'pro-monthly',
      );
      final monthlyUs = (monthly['regionalConfigs'] as List)
          .whereType<Map>()
          .firstWhere((c) => c['regionCode'] == 'US');
      expect(monthlyUs['price'], moneyFromDecimal('4.99'));
      // One-time product updated via the same batchUpdate upsert.
      expect(
        client.count(
          'POST',
          'androidpublisher/v3/applications/$pkg/oneTimeProducts:batchUpdate',
        ),
        1,
      );
      expect(logs.any((l) => l.contains('updated prices')), isTrue);
      expect(logs.any((l) => l.contains('updated one-time product')), isTrue);
    });

    test('extends legacy US-only configs to the full region table', () async {
      final client = FakeApiClient();
      final logs = <String>[];

      scriptConvertPrices(client, '800');
      scriptConvertPrices(client, '200');
      scriptConvertPrices(client, '2600');
      // Live pre-migration state: base plans carry a single US config.
      Map<String, Object?> legacyPlan(String id) => {
        'basePlanId': id,
        'state': 'ACTIVE',
        'regionalConfigs': [
          {
            'regionCode': 'US',
            'newSubscriberAvailability': true,
            'price': moneyFromDecimal(id == 'pro-yearly' ? '24.99' : '4.99'),
          },
        ],
      };
      for (var i = 0; i < 2; i++) {
        client.on(
          'GET',
          'androidpublisher/v3/applications/$pkg/subscriptions/pro',
          ApiResponse(
            200,
            _subscription([
              legacyPlan('pro-yearly'),
              legacyPlan('pro-monthly'),
            ]),
          ),
        );
      }
      client.on(
        'GET',
        'androidpublisher/v3/applications/$pkg/oneTimeProducts/pro_lifetime',
        ApiResponse(200, _oneTimeProduct('ACTIVE', '79.99')),
      );

      final provisioner = PlayProvisioner(
        client: client,
        packageName: pkg,
        log: logs.add,
      );
      final ok = await provisioner.run(
        basePlans: basePlans,
        lifetimePriceUsd: '79.99',
      );

      expect(ok, isTrue);
      final patches = client.bodiesFor(
        'PATCH',
        'androidpublisher/v3/applications/$pkg/subscriptions/pro',
      );
      expect(patches, hasLength(1));
      final patchedPlans = patches.single['basePlans'] as List;
      for (final plan in patchedPlans.whereType<Map>()) {
        final regions = (plan['regionalConfigs'] as List).whereType<Map>().map(
          (c) => c['regionCode'],
        );
        expect(regions, ['DE', 'JP', 'US']);
      }
      // The PATCH must carry the table's regions version (not the legacy
      // 2022/02 default) or Play rejects currency-changed regions like BG.
      final patchRequest = client.requests.singleWhere(
        (r) => r.startsWith('PATCH '),
      );
      expect(patchRequest, contains('regionsVersion.version=2025/03'));
      // OTP already had the full table — untouched.
      expect(
        client.count(
          'POST',
          'androidpublisher/v3/applications/$pkg/oneTimeProducts:batchUpdate',
        ),
        0,
      );
    });

    test('re-applies the listing when its title drifted', () async {
      final client = FakeApiClient();
      final logs = <String>[];

      scriptConvertPrices(client, '800');
      scriptConvertPrices(client, '200');
      scriptConvertPrices(client, '2600');
      for (var i = 0; i < 2; i++) {
        client.on(
          'GET',
          'androidpublisher/v3/applications/$pkg/subscriptions/pro',
          ApiResponse(
            200,
            _subscription([
              _plan('pro-yearly', 'ACTIVE', '24.99'),
              _plan('pro-monthly', 'ACTIVE', '4.99', jpUnits: '200'),
            ]),
          ),
        );
      }
      // Price matches, but the listing still has the old em-dash title —
      // the upsert must run to fix it. Re-read after the update returns
      // the corrected listing (ACTIVE, so no activation call).
      client.on(
        'GET',
        'androidpublisher/v3/applications/$pkg/oneTimeProducts/pro_lifetime',
        ApiResponse(
          200,
          _oneTimeProduct('ACTIVE', '79.99', title: 'Pro — Lifetime'),
        ),
      );
      client.on(
        'GET',
        'androidpublisher/v3/applications/$pkg/oneTimeProducts/pro_lifetime',
        ApiResponse(200, _oneTimeProduct('ACTIVE', '79.99')),
      );

      final provisioner = PlayProvisioner(
        client: client,
        packageName: pkg,
        log: logs.add,
      );
      final ok = await provisioner.run(
        basePlans: basePlans,
        lifetimePriceUsd: '79.99',
      );

      expect(ok, isTrue);
      expect(
        client.count(
          'POST',
          'androidpublisher/v3/applications/$pkg/oneTimeProducts:batchUpdate',
        ),
        1,
      );
      expect(logs.any((l) => l.contains('listing title')), isTrue);
      // No subscription PATCH, no activation calls — price matched.
      expect(client.requests.where((r) => r.startsWith('PATCH')), isEmpty);
      expect(
        client.requests.where((r) => r.contains('batchUpdateStates')),
        isEmpty,
      );
    });
  });
}
