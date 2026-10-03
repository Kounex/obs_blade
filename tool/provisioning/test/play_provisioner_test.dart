import 'package:provisioning/src/api_client.dart';
import 'package:provisioning/src/money.dart';
import 'package:provisioning/src/play_payloads.dart';
import 'package:provisioning/src/play_provisioner.dart';
import 'package:provisioning/src/pricing_targets.dart';
import 'package:test/test.dart';

import 'fake_api_client.dart';

const pkg = 'com.kounex.obsBlade';
const basePlans = [
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
const lifetimePrice = '99.99';

Map<String, Object?> _subscription(List<Map<String, Object?>> plans) => {
  'productId': 'pro',
  'packageName': pkg,
  'basePlans': plans,
};

/// The wanted per-region prices for a USD nominal, built from the checked-in
/// [PricingTargets] table exactly the way the provisioner builds them.
RegionPrices wantedPrices(String priceUsd) => {
  for (final entry in PricingTargets.playRegionCurrency.entries)
    if (PricingTargets.target(entry.value, priceUsd, region: entry.key)
        case final target?)
      entry.key: moneyFromDecimal(target, currencyCode: entry.value),
};

/// The wanted per-region configs for a plan/product at [priceUsd].
List<Map<String, Object?>> _configs(
  String priceUsd, {
  required bool subscription,
}) => regionalConfigList(wantedPrices(priceUsd), subscription: subscription);

Map<String, Object?> _plan(String id, String state, String priceUsd) => {
  'basePlanId': id,
  'state': state,
  'regionalConfigs': _configs(priceUsd, subscription: true),
};

Map<String, Object?> _oneTimeProduct(
  String state,
  String priceUsd, {
  String? title,
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
        subscription: false,
      ),
    },
  ],
};

/// regionCode → price map for one plan's config list.
Map<String, Map> _pricesByRegion(Map plan) => {
  for (final c in (plan['regionalConfigs'] as List).whereType<Map>())
    c['regionCode'] as String: c['price'] as Map,
};

void main() {
  group('PlayProvisioner', () {
    test('creates and activates everything when nothing exists', () async {
      final client = FakeApiClient();
      final logs = <String>[];

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
        lifetimePriceUsd: lifetimePrice,
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

      // The create carries the table's regions version or Play rejects
      // currency-changed regions (e.g. BG → EUR).
      final createRequest = client.requests.singleWhere(
        (r) => r.startsWith(
          'POST androidpublisher/v3/applications/$pkg/subscriptions?',
        ),
      );
      expect(
        createRequest,
        contains('regionsVersion.version=${PricingTargets.googleTableVersion}'),
      );

      // The created subscription carries the full per-region table from
      // PricingTargets: anchors at nominal, everything else Google-table.
      final createBody = client
          .bodiesFor(
            'POST',
            'androidpublisher/v3/applications/$pkg/subscriptions',
          )
          .single;
      final yearlyPlan = (createBody['basePlans'] as List)
          .whereType<Map>()
          .firstWhere((b) => b['basePlanId'] == 'pro-yearly');
      final yearly = _pricesByRegion(yearlyPlan);
      expect(yearly.length, PricingTargets.playRegionCurrency.length);
      expect(yearly['US'], {
        'currencyCode': 'USD',
        'units': '49',
        'nanos': 990000000,
      });
      expect(yearly['DE'], {
        'currencyCode': 'EUR',
        'units': '49',
        'nanos': 990000000,
      });
      expect(yearly['GB'], {
        'currencyCode': 'GBP',
        'units': '49',
        'nanos': 990000000,
      });
      expect(yearly['JP'], {
        'currencyCode': 'JPY',
        'units': '8700',
        'nanos': 0,
      });
      expect(yearly['TR'], {
        'currencyCode': 'TRY',
        'units': '2949',
        'nanos': 990000000,
      });
      expect(yearly['DK'], {'currencyCode': 'DKK', 'units': '415', 'nanos': 0});
      // CHF splits per region (Google prices CH and LI differently).
      expect(yearly['CH'], {'currencyCode': 'CHF', 'units': '41', 'nanos': 0});
      expect(yearly['LI'], {'currencyCode': 'CHF', 'units': '45', 'nanos': 0});

      final monthlyPlan = (createBody['basePlans'] as List)
          .whereType<Map>()
          .firstWhere((b) => b['basePlanId'] == 'pro-monthly');
      final monthly = _pricesByRegion(monthlyPlan);
      expect(monthly['US'], {
        'currencyCode': 'USD',
        'units': '4',
        'nanos': 990000000,
      });
      expect(monthly['JP'], {
        'currencyCode': 'JPY',
        'units': '860',
        'nanos': 0,
      });
      expect(monthly['TR'], {
        'currencyCode': 'TRY',
        'units': '294',
        'nanos': 990000000,
      });
      expect(monthly['CH'], {
        'currencyCode': 'CHF',
        'units': '4',
        'nanos': 100000000,
      });
      expect(monthly['LI'], {
        'currencyCode': 'CHF',
        'units': '4',
        'nanos': 500000000,
      });
    });

    test('is a no-op when everything already exists and is active', () async {
      final client = FakeApiClient();
      final logs = <String>[];

      // Scripted twice: once for the existence/base-plan check, once for
      // the post-create state re-read.
      for (var i = 0; i < 2; i++) {
        client.on(
          'GET',
          'androidpublisher/v3/applications/$pkg/subscriptions/pro',
          ApiResponse(
            200,
            _subscription([
              _plan('pro-yearly', 'ACTIVE', '49.99'),
              _plan('pro-monthly', 'ACTIVE', '4.99'),
            ]),
          ),
        );
      }
      client.on(
        'GET',
        'androidpublisher/v3/applications/$pkg/oneTimeProducts/pro_lifetime',
        ApiResponse(200, _oneTimeProduct('ACTIVE', lifetimePrice)),
      );

      final provisioner = PlayProvisioner(
        client: client,
        packageName: pkg,
        log: logs.add,
      );
      final ok = await provisioner.run(
        basePlans: basePlans,
        lifetimePriceUsd: lifetimePrice,
      );

      expect(ok, isTrue);
      expect(
        client.requests.where((r) => !r.startsWith('GET')),
        isEmpty,
        reason: 'matching prices + states must not write anything',
      );
      expect(logs.any((l) => l.contains('already exists')), isTrue);
      expect(logs.any((l) => l.contains('already ACTIVE')), isTrue);
    });

    test(
      'patches in a missing base plan on an existing subscription',
      () async {
        final client = FakeApiClient();
        final logs = <String>[];

        client.on(
          'GET',
          'androidpublisher/v3/applications/$pkg/subscriptions/pro',
          ApiResponse(
            200,
            _subscription([_plan('pro-yearly', 'ACTIVE', '49.99')]),
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
          ApiResponse(200, _oneTimeProduct('ACTIVE', lifetimePrice)),
        );

        final provisioner = PlayProvisioner(
          client: client,
          packageName: pkg,
          log: logs.add,
        );
        final ok = await provisioner.run(
          basePlans: basePlans,
          lifetimePriceUsd: lifetimePrice,
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

      // Yearly carries the old cheap Turkish tier (₺699.99 instead of the
      // wanted ₺2949.99); monthly is already correct. Scripted twice (check
      // + activation re-read).
      final driftedYearly = Map<String, Map<String, Object?>>.of(
        wantedPrices('49.99'),
      );
      driftedYearly['TR'] = moneyFromDecimal('699.99', currencyCode: 'TRY');
      for (var i = 0; i < 2; i++) {
        client.on(
          'GET',
          'androidpublisher/v3/applications/$pkg/subscriptions/pro',
          ApiResponse(
            200,
            _subscription([
              {
                'basePlanId': 'pro-yearly',
                'state': 'ACTIVE',
                'regionalConfigs': regionalConfigList(
                  driftedYearly,
                  subscription: true,
                ),
              },
              _plan('pro-monthly', 'ACTIVE', '4.99'),
            ]),
          ),
        );
      }
      // Lifetime at the old cheap Turkish price, then re-read after the
      // update with the corrected table.
      final driftedLifetime = Map<String, Map<String, Object?>>.of(
        wantedPrices(lifetimePrice),
      );
      driftedLifetime['TR'] = moneyFromDecimal('1389.99', currencyCode: 'TRY');
      client.on(
        'GET',
        'androidpublisher/v3/applications/$pkg/oneTimeProducts/pro_lifetime',
        ApiResponse(200, {
          'productId': 'pro_lifetime',
          'listings': [
            {'languageCode': 'en-US', 'title': PlayProvisioner.lifetimeTitle},
          ],
          'purchaseOptions': [
            {
              'purchaseOptionId': 'pro-lifetime',
              'state': 'ACTIVE',
              'regionalPricingAndAvailabilityConfigs': regionalConfigList(
                driftedLifetime,
                subscription: false,
              ),
            },
          ],
        }),
      );
      client.on(
        'GET',
        'androidpublisher/v3/applications/$pkg/oneTimeProducts/pro_lifetime',
        ApiResponse(200, _oneTimeProduct('ACTIVE', lifetimePrice)),
      );

      final provisioner = PlayProvisioner(
        client: client,
        packageName: pkg,
        log: logs.add,
      );
      final ok = await provisioner.run(
        basePlans: basePlans,
        lifetimePriceUsd: lifetimePrice,
      );

      expect(ok, isTrue);
      final patches = client.bodiesFor(
        'PATCH',
        'androidpublisher/v3/applications/$pkg/subscriptions/pro',
      );
      expect(patches, hasLength(1));
      final patchedPlans = patches.first['basePlans'] as List;
      final yearly = _pricesByRegion(
        patchedPlans.whereType<Map>().firstWhere(
          (b) => b['basePlanId'] == 'pro-yearly',
        ),
      );
      expect(yearly['US'], {
        'currencyCode': 'USD',
        'units': '49',
        'nanos': 990000000,
      });
      expect(yearly['TR'], {
        'currencyCode': 'TRY',
        'units': '2949',
        'nanos': 990000000,
      });
      // Monthly plan carried over untouched.
      final monthly = _pricesByRegion(
        patchedPlans.whereType<Map>().firstWhere(
          (b) => b['basePlanId'] == 'pro-monthly',
        ),
      );
      expect(monthly['US'], moneyFromDecimal('4.99'));
      expect(monthly['TR'], {
        'currencyCode': 'TRY',
        'units': '294',
        'nanos': 990000000,
      });
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

      // Live pre-migration state: base plans carry a single US config.
      Map<String, Object?> legacyPlan(String id) => {
        'basePlanId': id,
        'state': 'ACTIVE',
        'regionalConfigs': [
          {
            'regionCode': 'US',
            'newSubscriberAvailability': true,
            'price': moneyFromDecimal(id == 'pro-yearly' ? '49.99' : '4.99'),
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
        ApiResponse(200, _oneTimeProduct('ACTIVE', lifetimePrice)),
      );

      final provisioner = PlayProvisioner(
        client: client,
        packageName: pkg,
        log: logs.add,
      );
      final ok = await provisioner.run(
        basePlans: basePlans,
        lifetimePriceUsd: lifetimePrice,
      );

      expect(ok, isTrue);
      final patches = client.bodiesFor(
        'PATCH',
        'androidpublisher/v3/applications/$pkg/subscriptions/pro',
      );
      expect(patches, hasLength(1));
      final patchedPlans = patches.single['basePlans'] as List;
      for (final plan in patchedPlans.whereType<Map>()) {
        expect(
          (plan['regionalConfigs'] as List).length,
          PricingTargets.playRegionCurrency.length,
        );
      }
      // The PATCH must carry the table's regions version (not the legacy
      // 2022/02 default) or Play rejects currency-changed regions like BG.
      final patchRequest = client.requests.singleWhere(
        (r) => r.startsWith('PATCH '),
      );
      expect(
        patchRequest,
        contains('regionsVersion.version=${PricingTargets.googleTableVersion}'),
      );
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

      for (var i = 0; i < 2; i++) {
        client.on(
          'GET',
          'androidpublisher/v3/applications/$pkg/subscriptions/pro',
          ApiResponse(
            200,
            _subscription([
              _plan('pro-yearly', 'ACTIVE', '49.99'),
              _plan('pro-monthly', 'ACTIVE', '4.99'),
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
          _oneTimeProduct('ACTIVE', lifetimePrice, title: 'Pro — Lifetime'),
        ),
      );
      client.on(
        'GET',
        'androidpublisher/v3/applications/$pkg/oneTimeProducts/pro_lifetime',
        ApiResponse(200, _oneTimeProduct('ACTIVE', lifetimePrice)),
      );

      final provisioner = PlayProvisioner(
        client: client,
        packageName: pkg,
        log: logs.add,
      );
      final ok = await provisioner.run(
        basePlans: basePlans,
        lifetimePriceUsd: lifetimePrice,
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

  group('PricingTargets', () {
    test('anchor currencies stay at the USD nominal', () {
      for (final currency in ['USD', 'EUR', 'GBP']) {
        expect(PricingTargets.target(currency, '4.99'), '4.99');
        expect(PricingTargets.target(currency, '49.99'), '49.99');
        expect(PricingTargets.target(currency, '99.99'), '99.99');
      }
    });

    test('converted currencies use the Google table values', () {
      expect(PricingTargets.target('TRY', '4.99'), '294.99');
      expect(PricingTargets.target('TRY', '49.99'), '2949.99');
      expect(PricingTargets.target('JPY', '4.99'), '860');
      expect(PricingTargets.target('JPY', '49.99'), '8700');
      expect(PricingTargets.target('DKK', '4.99'), '41');
      expect(PricingTargets.target('EGP', '4.99'), '299.99');
      // No Play in China — Apple's mainland market pricing is kept.
      expect(PricingTargets.target('CNY', '4.99'), '26');
      expect(PricingTargets.target('CNY', '49.99'), '222');
    });

    test('CHF splits per region', () {
      expect(PricingTargets.target('CHF', '4.99'), isNull);
      expect(PricingTargets.target('CHF', '4.99', region: 'CH'), '4.10');
      expect(PricingTargets.target('CHF', '4.99', region: 'LI'), '4.50');
    });

    test('unknown currencies and nominals return null', () {
      expect(PricingTargets.target('QQQ', '4.99'), isNull);
      expect(PricingTargets.target('USD', '12.34'), isNull);
    });

    test('every Play region has a target for all three nominals', () {
      for (final entry in PricingTargets.playRegionCurrency.entries) {
        for (final nominal in ['4.99', '49.99', '99.99']) {
          expect(
            PricingTargets.target(entry.value, nominal, region: entry.key),
            isNotNull,
            reason: '${entry.key} (${entry.value}) @ $nominal',
          );
        }
      }
      expect(PricingTargets.playRegionCurrency, isNot(contains('CN')));
    });
  });
}
