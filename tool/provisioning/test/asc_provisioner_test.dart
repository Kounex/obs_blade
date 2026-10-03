import 'dart:convert';

import 'package:provisioning/src/api_client.dart';
import 'package:provisioning/src/asc_provisioner.dart';
import 'package:test/test.dart';

import 'fake_api_client.dart';

/// base64url-encoded JSON id in Apple's price-point format
/// (`{"s":…,"t":…,"p":tier}`) — the provisioner compares the embedded tier.
String fakePointId(String tier, {String s = 'i1'}) => base64Url
    .encode(utf8.encode('{"s":"$s","t":"USA","p":"$tier"}'))
    .replaceAll('=', '');

const subs = [
  SubscriptionSpec(
    productId: 'pro_yearly',
    name: 'Pro - Yearly',
    description: 'Yearly Pro Subscription',
    subscriptionPeriod: 'ONE_YEAR',
    priceUsd: '49.99',
  ),
  SubscriptionSpec(
    productId: 'pro_monthly',
    name: 'Pro - Monthly',
    description: 'Monthly Pro Subscription',
    subscriptionPeriod: 'ONE_MONTH',
    priceUsd: '4.99',
  ),
];

Map<String, Object?> _resource(
  String type,
  String id, [
  Map<String, Object?> attributes = const {},
]) => {'type': type, 'id': id, 'attributes': attributes};

/// Scripts the territory list the provisioner reads for the per-territory
/// currency map (fetched once per run, then cached). In create flows the
/// availability setup reads the same endpoint per subscription — script
/// [times] accordingly (the ids are all that read uses).
void scriptTerritories(
  FakeApiClient client,
  Map<String, String> currencies, {
  int times = 1,
}) {
  for (var i = 0; i < times; i++) {
    client.on(
      'GET',
      'v1/territories',
      ApiResponse(200, {
        'data': [
          for (final e in currencies.entries)
            _resource('territories', e.key, {'currency': e.value}),
        ],
      }),
    );
  }
}

/// Scripts an existing availability plus its territory list (the related
/// collection endpoint the provisioner reads territory ids from).
void scriptAvailability(
  FakeApiClient client,
  String subId,
  List<String> territories,
) {
  client.on(
    'GET',
    'v1/subscriptionAvailabilities/$subId',
    ApiResponse(200, {
      'data': _resource('subscriptionAvailabilities', 'a-$subId'),
    }),
  );
  client.on(
    'GET',
    'v1/subscriptionAvailabilities/$subId/availableTerritories',
    ApiResponse(200, {
      'data': [for (final t in territories) _resource('territories', t)],
    }),
  );
}

/// A prices response with one current (startDate == null) record at
/// [customerPrice] via price point [pointId].
ApiResponse currentPrice(String subId, String pointId, String customerPrice) =>
    ApiResponse(200, {
      'data': [
        {
          'type': 'subscriptionPrices',
          'id': 'p-$subId',
          'attributes': {'startDate': null},
          'relationships': {
            'subscriptionPricePoint': {
              'data': {'type': 'subscriptionPricePoints', 'id': pointId},
            },
          },
        },
      ],
      'included': [
        _resource('subscriptionPricePoints', pointId, {
          'customerPrice': customerPrice,
        }),
      ],
    });

/// A prices response with a current record at [currentPrice] (point
/// [currentPointId]) plus a SCHEDULED change (future [startDate]) to
/// [scheduledPrice] via point [scheduledPointId].
ApiResponse priceWithScheduledChange(
  String subId,
  String currentPointId,
  String currentPrice,
  String scheduledPointId,
  String scheduledPrice,
  String startDate,
) => ApiResponse(200, {
  'data': [
    {
      'type': 'subscriptionPrices',
      'id': 'p-$subId',
      'attributes': {'startDate': null},
      'relationships': {
        'subscriptionPricePoint': {
          'data': {'type': 'subscriptionPricePoints', 'id': currentPointId},
        },
      },
    },
    {
      'type': 'subscriptionPrices',
      'id': 'p-$subId-scheduled',
      'attributes': {'startDate': startDate},
      'relationships': {
        'subscriptionPricePoint': {
          'data': {'type': 'subscriptionPricePoints', 'id': scheduledPointId},
        },
      },
    },
  ],
  'included': [
    _resource('subscriptionPricePoints', currentPointId, {
      'customerPrice': currentPrice,
    }),
    _resource('subscriptionPricePoints', scheduledPointId, {
      'customerPrice': scheduledPrice,
    }),
  ],
});

/// A price-points page with a single point.
ApiResponse pricePoints(String pointId, String customerPrice) =>
    ApiResponse(200, {
      'data': [
        _resource('subscriptionPricePoints', pointId, {
          'customerPrice': customerPrice,
        }),
      ],
    });

/// Scripts the group + both subscriptions (+ localizations) as already
/// existing. Localization attributes default to the spec values (matching);
/// pass [s1LocAttributes] / [s2LocAttributes] to script drift.
void scriptExistingSubs(
  FakeApiClient client, {
  Map<String, Object?>? s1LocAttributes,
  Map<String, Object?>? s2LocAttributes,
  String? s1ReferenceName,
  String? s2ReferenceName,
}) {
  client.on(
    'GET',
    'v1/apps/1234/subscriptionGroups',
    ApiResponse(200, {
      'data': [
        _resource('subscriptionGroups', 'g1', {'referenceName': 'Pro'}),
      ],
    }),
  );
  client.on(
    'GET',
    'v1/subscriptionGroups/g1/subscriptionGroupLocalizations',
    ApiResponse(200, {
      'data': [
        _resource('subscriptionGroupLocalizations', 'gl1', {'locale': 'en-US'}),
      ],
    }),
  );
  for (var i = 0; i < 2; i++) {
    client.on(
      'GET',
      'v1/subscriptionGroups/g1/subscriptions',
      ApiResponse(200, {
        'data': [
          _resource('subscriptions', 's1', {
            'productId': 'pro_yearly',
            'name': s1ReferenceName ?? subs[0].name,
          }),
          _resource('subscriptions', 's2', {
            'productId': 'pro_monthly',
            'name': s2ReferenceName ?? subs[1].name,
          }),
        ],
      }),
    );
  }
  final overrides = [s1LocAttributes, s2LocAttributes];
  for (var i = 0; i < 2; i++) {
    final spec = subs[i];
    client.on(
      'GET',
      'v1/subscriptions/s${i + 1}/subscriptionLocalizations',
      ApiResponse(200, {
        'data': [
          _resource(
            'subscriptionLocalizations',
            'l-s${i + 1}',
            overrides[i] ??
                {
                  'locale': 'en-US',
                  'name': spec.name,
                  'description': spec.description,
                },
          ),
        ],
      }),
    );
  }
}

/// Scripts the IAP (+ localization) as already existing, with its price
/// schedule already at [tier] and — unless [scriptPricePoints] is false —
/// the matching point available. [iapLocAttributes] overrides the
/// (default: matching) localization attributes.
void scriptExistingIap(
  FakeApiClient client,
  String tier,
  String price, {
  Map<String, Object?>? iapLocAttributes,
  bool scriptPricePoints = true,
  String? iapReferenceName,
}) {
  client.on(
    'GET',
    'v1/apps/1234/inAppPurchasesV2',
    ApiResponse(200, {
      'data': [
        _resource('inAppPurchases', 'i1', {
          'productId': 'pro_lifetime',
          'name': iapReferenceName ?? AscProvisioner.lifetimeName,
        }),
      ],
    }),
  );
  client.on(
    'GET',
    'v2/inAppPurchases/i1/inAppPurchaseLocalizations',
    ApiResponse(200, {
      'data': [
        _resource(
          'inAppPurchaseLocalizations',
          'il1',
          iapLocAttributes ??
              {
                'locale': 'en-US',
                'name': AscProvisioner.lifetimeName,
                'description': AscProvisioner.lifetimeDescription,
              },
        ),
      ],
    }),
  );
  client.on(
    'GET',
    'v2/inAppPurchases/i1/iapPriceSchedule',
    ApiResponse(200, {
      'data': {
        'type': 'inAppPurchasePriceSchedules',
        'id': 'sched1',
        'relationships': {
          'manualPrices': {
            'data': [
              {'type': 'inAppPurchasePrices', 'id': fakePointId(tier)},
            ],
          },
        },
      },
    }),
  );
  if (scriptPricePoints) {
    client.on(
      'GET',
      'v2/inAppPurchases/i1/pricePoints',
      ApiResponse(200, {
        'data': [
          _resource('inAppPurchasePricePoints', fakePointId(tier), {
            'customerPrice': price,
          }),
        ],
      }),
    );
  }
}

/// Scripts both subscriptions as available in the USA only, priced at the
/// wanted nominal with the matching price points — the steady state every
/// non-pricing test rides on.
void scriptPricedUsaSubs(FakeApiClient client) {
  scriptExistingSubs(client);
  scriptAvailability(client, 's1', ['USA']);
  scriptAvailability(client, 's2', ['USA']);
  scriptTerritories(client, {'USA': 'USD'});
  client.on(
    'GET',
    'v1/subscriptions/s1/prices',
    currentPrice('s1', 'pp-s1', '49.99'),
  );
  client.on(
    'GET',
    'v1/subscriptions/s1/pricePoints',
    pricePoints('pp-s1', '49.99'),
  );
  client.on(
    'GET',
    'v1/subscriptions/s2/prices',
    currentPrice('s2', 'pp-s2', '4.99'),
  );
  client.on(
    'GET',
    'v1/subscriptions/s2/pricePoints',
    pricePoints('pp-s2', '4.99'),
  );
}

void main() {
  group('AscProvisioner', () {
    test('creates everything when nothing exists', () async {
      final client = FakeApiClient();
      final logs = <String>[];

      client.on(
        'POST',
        'v1/subscriptionGroups',
        ApiResponse(201, {'data': _resource('subscriptionGroups', 'g1')}),
      );
      // subscriptions are created in order: yearly -> s1, monthly -> s2
      client.on(
        'POST',
        'v1/subscriptions',
        ApiResponse(201, {'data': _resource('subscriptions', 's1')}),
      );
      client.on(
        'POST',
        'v1/subscriptions',
        ApiResponse(201, {'data': _resource('subscriptions', 's2')}),
      );
      // Territories are fetched once per subscription (availability
      // creation) plus once for the currency map.
      scriptTerritories(client, {'USA': 'USD', 'DEU': 'EUR'}, times: 3);
      // Price points are looked up once per territory (USA, then DEU).
      for (var i = 0; i < 2; i++) {
        client.on(
          'GET',
          'v1/subscriptions/s1/pricePoints',
          pricePoints('pp-y', '49.99'),
        );
        client.on(
          'GET',
          'v1/subscriptions/s2/pricePoints',
          pricePoints('pp-m', '4.99'),
        );
      }
      client.on(
        'POST',
        'v2/inAppPurchases',
        ApiResponse(201, {'data': _resource('inAppPurchases', 'i1')}),
      );
      client.on(
        'GET',
        'v2/inAppPurchases/i1/iapPriceSchedule',
        ApiResponse(404, null),
      );
      client.on(
        'GET',
        'v2/inAppPurchases/i1/pricePoints',
        ApiResponse(200, {
          'data': [
            _resource('inAppPurchasePricePoints', 'pp-l', {
              'customerPrice': '79.99',
            }),
          ],
        }),
      );

      final provisioner = AscProvisioner(
        client: client,
        appId: '1234',
        log: logs.add,
      );
      final ok = await provisioner.run(
        subscriptions: subs,
        lifetimePriceUsd: '79.99',
      );

      expect(ok, isTrue);
      // Creates: group, group loc, 2 subs, 2 sub locs,
      // 2 subs × 2 territories prices, IAP, IAP loc, IAP price schedule.
      expect(client.count('POST', 'v1/subscriptionGroups'), 1);
      expect(client.count('POST', 'v1/subscriptionGroupLocalizations'), 1);
      expect(client.count('POST', 'v1/subscriptions'), 2);
      expect(client.count('POST', 'v1/subscriptionLocalizations'), 2);
      expect(client.count('POST', 'v1/subscriptionPrices'), 4);
      expect(client.count('POST', 'v1/subscriptionAvailabilities'), 2);
      expect(client.count('POST', 'v2/inAppPurchases'), 1);
      expect(client.count('POST', 'v1/inAppPurchaseLocalizations'), 1);
      expect(client.count('POST', 'v1/inAppPurchasePriceSchedules'), 1);

      // Localization creates carry the spec name AND description.
      final locBodies = client.bodiesFor(
        'POST',
        'v1/subscriptionLocalizations',
      );
      expect(
        ((locBodies.first['data'] as Map)['attributes'] as Map)['name'],
        'Pro - Yearly',
      );
      expect(
        ((locBodies.first['data'] as Map)['attributes'] as Map)['description'],
        'Yearly Pro Subscription',
      );

      // Availability covers all listed territories plus future ones.
      final availabilityBodies = client.bodiesFor(
        'POST',
        'v1/subscriptionAvailabilities',
      );
      final availabilityData =
          (availabilityBodies.first['data'] as Map)['relationships'] as Map;
      final territoryData =
          (availabilityData['availableTerritories'] as Map)['data'] as List;
      expect(territoryData.map((t) => (t as Map)['id']), ['USA', 'DEU']);
      expect(
        ((availabilityBodies.first['data'] as Map)['attributes']
            as Map)['availableInNewTerritories'],
        isTrue,
      );

      // Prices were attached to the right price points per territory —
      // yearly USA/DEU first, then monthly USA/DEU (spec order).
      final priceBodies = client.bodiesFor('POST', 'v1/subscriptionPrices');
      expect(priceBodies, hasLength(4));
      String pointOf(Map<String, Object?> body) =>
          ((((body['data'] as Map)['relationships']
                          as Map)['subscriptionPricePoint']
                      as Map)['data']
                  as Map)['id']
              as String;
      String territoryOf(Map<String, Object?> body) =>
          ((((body['data'] as Map)['relationships'] as Map)['territory']
                      as Map)['data']
                  as Map)['id']
              as String;
      expect(priceBodies.map(pointOf), ['pp-y', 'pp-y', 'pp-m', 'pp-m']);
      expect(priceBodies.map(territoryOf), ['USA', 'DEU', 'USA', 'DEU']);
    });

    test('is a no-op when everything already exists', () async {
      final client = FakeApiClient();
      final logs = <String>[];

      scriptPricedUsaSubs(client);
      scriptExistingIap(client, '10417', '79.99');

      final provisioner = AscProvisioner(
        client: client,
        appId: '1234',
        log: logs.add,
      );
      final ok = await provisioner.run(
        subscriptions: subs,
        lifetimePriceUsd: '79.99',
      );

      expect(ok, isTrue);
      expect(client.requests.where((r) => r.startsWith('POST')), isEmpty);
      expect(client.requests.where((r) => r.startsWith('PATCH')), isEmpty);
      expect(
        logs.where((l) => l.contains('already')).length,
        greaterThanOrEqualTo(8),
      );
    });

    test('PATCHes drifted localizations instead of re-creating them', () async {
      final client = FakeApiClient();
      final logs = <String>[];

      // s1 localization drifted (em-dash name, no description).
      scriptExistingSubs(
        client,
        s1LocAttributes: {
          'locale': 'en-US',
          'name': 'Pro — Yearly',
          'description': '',
        },
      );
      scriptAvailability(client, 's1', ['USA']);
      scriptAvailability(client, 's2', ['USA']);
      scriptTerritories(client, {'USA': 'USD'});
      client.on(
        'GET',
        'v1/subscriptions/s1/prices',
        currentPrice('s1', 'pp-s1', '49.99'),
      );
      client.on(
        'GET',
        'v1/subscriptions/s1/pricePoints',
        pricePoints('pp-s1', '49.99'),
      );
      client.on(
        'GET',
        'v1/subscriptions/s2/prices',
        currentPrice('s2', 'pp-s2', '4.99'),
      );
      client.on(
        'GET',
        'v1/subscriptions/s2/pricePoints',
        pricePoints('pp-s2', '4.99'),
      );
      // IAP localization drifted too (em-dash name, no description).
      scriptExistingIap(
        client,
        '10417',
        '79.99',
        iapLocAttributes: {'locale': 'en-US', 'name': 'Pro — Lifetime'},
      );

      final provisioner = AscProvisioner(
        client: client,
        appId: '1234',
        log: logs.add,
      );
      final ok = await provisioner.run(
        subscriptions: subs,
        lifetimePriceUsd: '79.99',
      );

      expect(ok, isTrue);
      expect(client.count('POST', 'v1/subscriptionLocalizations'), 0);
      expect(client.count('POST', 'v1/inAppPurchaseLocalizations'), 0);

      final subPatch = client.bodiesFor(
        'PATCH',
        'v1/subscriptionLocalizations/l-s1',
      );
      expect(subPatch, hasLength(1));
      final subAttrs = (subPatch.single['data'] as Map)['attributes'] as Map;
      expect(subAttrs['name'], 'Pro - Yearly');
      expect(subAttrs['description'], 'Yearly Pro Subscription');
      expect(
        (subPatch.single['data'] as Map)['type'],
        'subscriptionLocalizations',
      );

      final iapPatch = client.bodiesFor(
        'PATCH',
        'v1/inAppPurchaseLocalizations/il1',
      );
      expect(iapPatch, hasLength(1));
      final iapAttrs = (iapPatch.single['data'] as Map)['attributes'] as Map;
      expect(iapAttrs['name'], 'Pro - Lifetime');
      expect(iapAttrs['description'], 'Lifetime Pro Access');
      expect(logs.where((l) => l.contains('drifted')).length, 2);
    });

    test('PATCHes drifted reference names (subscriptions + IAP)', () async {
      final client = FakeApiClient();
      final logs = <String>[];

      scriptExistingSubs(
        client,
        s1ReferenceName: 'Pro — Yearly',
        s2ReferenceName: 'Pro — Monthly',
      );
      scriptAvailability(client, 's1', ['USA']);
      scriptAvailability(client, 's2', ['USA']);
      scriptTerritories(client, {'USA': 'USD'});
      client.on(
        'GET',
        'v1/subscriptions/s1/prices',
        currentPrice('s1', 'pp-s1', '49.99'),
      );
      client.on(
        'GET',
        'v1/subscriptions/s1/pricePoints',
        pricePoints('pp-s1', '49.99'),
      );
      client.on(
        'GET',
        'v1/subscriptions/s2/prices',
        currentPrice('s2', 'pp-s2', '4.99'),
      );
      client.on(
        'GET',
        'v1/subscriptions/s2/pricePoints',
        pricePoints('pp-s2', '4.99'),
      );
      scriptExistingIap(
        client,
        '10417',
        '79.99',
        iapReferenceName: 'Pro — Lifetime',
      );

      final provisioner = AscProvisioner(
        client: client,
        appId: '1234',
        log: logs.add,
      );
      final ok = await provisioner.run(
        subscriptions: subs,
        lifetimePriceUsd: '79.99',
      );

      expect(ok, isTrue);
      final s1Patch = client.bodiesFor('PATCH', 'v1/subscriptions/s1');
      expect(s1Patch, hasLength(1));
      expect(
        ((s1Patch.single['data'] as Map)['attributes'] as Map)['name'],
        'Pro - Yearly',
      );
      expect((s1Patch.single['data'] as Map)['type'], 'subscriptions');
      expect(client.bodiesFor('PATCH', 'v1/subscriptions/s2'), hasLength(1));
      final iapPatch = client.bodiesFor('PATCH', 'v2/inAppPurchases/i1');
      expect(iapPatch, hasLength(1));
      expect(
        ((iapPatch.single['data'] as Map)['attributes'] as Map)['name'],
        'Pro - Lifetime',
      );
      expect((iapPatch.single['data'] as Map)['type'], 'inAppPurchases');
      // Localizations match (fixtures default to spec values) — no
      // localization PATCHes.
      expect(
        client.requests.where(
          (r) => r.contains('Localizations') && r.startsWith('PATCH'),
        ),
        isEmpty,
      );
    });

    test(
      'prices every territory from the targets table, skips matching ones',
      () async {
        final client = FakeApiClient();
        final logs = <String>[];

        scriptExistingSubs(client);
        // USA already at the wanted price, DEU + JPN unpriced with exact
        // table points (EUR anchor 49.99, JPY Google-table 8700).
        scriptAvailability(client, 's1', ['USA', 'DEU', 'JPN']);
        scriptAvailability(client, 's2', ['USA']);
        scriptTerritories(client, {'USA': 'USD', 'DEU': 'EUR', 'JPN': 'JPY'});
        client.on(
          'GET',
          'v1/subscriptions/s1/prices',
          currentPrice('s1', 'pp-usa', '49.99'),
        );
        client.on(
          'GET',
          'v1/subscriptions/s1/pricePoints',
          pricePoints('pp-usa', '49.99'),
        );
        client.on(
          'GET',
          'v1/subscriptions/s1/pricePoints',
          pricePoints('pp-deu', '49.99'),
        );
        client.on(
          'GET',
          'v1/subscriptions/s1/pricePoints',
          pricePoints('pp-jpn', '8700'),
        );
        client.on(
          'GET',
          'v1/subscriptions/s2/prices',
          currentPrice('s2', 'pp-s2', '4.99'),
        );
        client.on(
          'GET',
          'v1/subscriptions/s2/pricePoints',
          pricePoints('pp-s2', '4.99'),
        );
        scriptExistingIap(client, '10417', '79.99');

        final provisioner = AscProvisioner(
          client: client,
          appId: '1234',
          log: logs.add,
        );
        final ok = await provisioner.run(
          subscriptions: subs,
          lifetimePriceUsd: '79.99',
        );

        expect(ok, isTrue);
        final priceBodies = client.bodiesFor('POST', 'v1/subscriptionPrices');
        expect(priceBodies, hasLength(2)); // DEU + JPN
        String pointOf(Map<String, Object?> body) =>
            ((((body['data'] as Map)['relationships']
                            as Map)['subscriptionPricePoint']
                        as Map)['data']
                    as Map)['id']
                as String;
        String territoryOf(Map<String, Object?> body) =>
            ((((body['data'] as Map)['relationships'] as Map)['territory']
                        as Map)['data']
                    as Map)['id']
                as String;
        expect(priceBodies.map(pointOf), ['pp-deu', 'pp-jpn']);
        expect(priceBodies.map(territoryOf), ['DEU', 'JPN']);
        expect(
          logs.any((l) => l.contains('USA: price already 49.99 — skipping')),
          isTrue,
        );
        // Exact table prices — no snap notes.
        expect(logs.any((l) => l.contains('snapped')), isFalse);
      },
    );

    test('snaps to the nearest price point when no exact one exists', () async {
      final client = FakeApiClient();
      final logs = <String>[];

      scriptExistingSubs(client);
      scriptAvailability(client, 's1', ['JPN']);
      scriptAvailability(client, 's2', ['TUR']);
      scriptTerritories(client, {'JPN': 'JPY', 'TUR': 'TRY'});
      // JPN (yearly target ¥8700): points at 8500 / 9000 — the nearer 8500
      // wins (2.3% off → snap note) and the scan stops there (points come
      // back sorted ascending), never following the cursor.
      client.on(
        'GET',
        'v1/subscriptions/s1/pricePoints',
        ApiResponse(200, {
          'data': [
            _resource('subscriptionPricePoints', 'pp-jpn-low', {
              'customerPrice': '8500',
            }),
            _resource('subscriptionPricePoints', 'pp-jpn-high', {
              'customerPrice': '9000',
            }),
          ],
          'meta': {
            'paging': {'total': 800, 'nextCursor': 'AMg', 'limit': 200},
          },
        }),
      );
      // TUR (monthly target ₺294.99): 289.99 is much nearer than the next
      // point above (1.7% off → no snap note).
      client.on(
        'GET',
        'v1/subscriptions/s2/pricePoints',
        ApiResponse(200, {
          'data': [
            _resource('subscriptionPricePoints', 'pp-tur-low', {
              'customerPrice': '289.99',
            }),
            _resource('subscriptionPricePoints', 'pp-tur-high', {
              'customerPrice': '350',
            }),
          ],
        }),
      );
      scriptExistingIap(client, '10417', '79.99');

      final provisioner = AscProvisioner(
        client: client,
        appId: '1234',
        log: logs.add,
      );
      final ok = await provisioner.run(
        subscriptions: subs,
        lifetimePriceUsd: '79.99',
      );

      expect(ok, isTrue);
      final priceBodies = client.bodiesFor('POST', 'v1/subscriptionPrices');
      expect(priceBodies, hasLength(2));
      String pointOf(Map<String, Object?> body) =>
          ((((body['data'] as Map)['relationships']
                          as Map)['subscriptionPricePoint']
                      as Map)['data']
                  as Map)['id']
              as String;
      expect(priceBodies.map(pointOf), ['pp-jpn-low', 'pp-tur-low']);
      // Early exit: the second page was never fetched.
      expect(client.requests.any((r) => r.contains('cursor=AMg')), isFalse);
      // Only JPN deviates beyond the 2% snap-warning threshold.
      expect(logs.any((l) => l.contains('JPN→8500 (target 8700)')), isTrue);
      expect(logs.any((l) => l.contains('TUR→')), isFalse);
      expect(
        logs.any(
          (l) => l.contains('JPN: set price 8500 — snapped from target 8700'),
        ),
        isTrue,
      );
    });

    test(
      'snaps to the highest point when every point is below the target',
      () async {
        final client = FakeApiClient();
        final logs = <String>[];

        scriptExistingSubs(client);
        scriptAvailability(client, 's1', ['USA']);
        scriptAvailability(client, 's2', ['SWE']);
        scriptTerritories(client, {'USA': 'USD', 'SWE': 'SEK'});
        client.on(
          'GET',
          'v1/subscriptions/s1/prices',
          currentPrice('s1', 'pp-s1', '49.99'),
        );
        client.on(
          'GET',
          'v1/subscriptions/s1/pricePoints',
          pricePoints('pp-s1', '49.99'),
        );
        // SWE (monthly target 65 kr): every point is below the target — the
        // highest one wins.
        client.on(
          'GET',
          'v1/subscriptions/s2/pricePoints',
          ApiResponse(200, {
            'data': [
              _resource('subscriptionPricePoints', 'pp-swe-low', {
                'customerPrice': '55',
              }),
              _resource('subscriptionPricePoints', 'pp-swe-high', {
                'customerPrice': '60',
              }),
            ],
          }),
        );
        scriptExistingIap(client, '10417', '79.99');

        final provisioner = AscProvisioner(
          client: client,
          appId: '1234',
          log: logs.add,
        );
        final ok = await provisioner.run(
          subscriptions: subs,
          lifetimePriceUsd: '79.99',
        );

        expect(ok, isTrue);
        final priceBodies = client.bodiesFor('POST', 'v1/subscriptionPrices');
        expect(priceBodies, hasLength(1));
        final rels =
            (priceBodies.single['data'] as Map)['relationships'] as Map;
        expect(((rels['territory'] as Map)['data'] as Map)['id'], 'SWE');
        expect(
          ((rels['subscriptionPricePoint'] as Map)['data'] as Map)['id'],
          'pp-swe-high',
        );
        expect(logs.any((l) => l.contains('SWE→60 (target 65)')), isTrue);
      },
    );

    test(
      'a territory whose currency has no target is skipped with a warning',
      () async {
        final client = FakeApiClient();
        final logs = <String>[];

        scriptExistingSubs(client);
        scriptAvailability(client, 's1', ['XYZ']);
        scriptAvailability(client, 's2', ['USA']);
        scriptTerritories(client, {'XYZ': 'QQQ', 'USA': 'USD'});
        client.on(
          'GET',
          'v1/subscriptions/s2/prices',
          currentPrice('s2', 'pp-s2', '4.99'),
        );
        client.on(
          'GET',
          'v1/subscriptions/s2/pricePoints',
          pricePoints('pp-s2', '4.99'),
        );
        scriptExistingIap(client, '10417', '79.99');

        final provisioner = AscProvisioner(
          client: client,
          appId: '1234',
          log: logs.add,
        );
        final ok = await provisioner.run(
          subscriptions: subs,
          lifetimePriceUsd: '79.99',
        );

        expect(ok, isTrue); // missing targets don't fail the run
        expect(client.count('POST', 'v1/subscriptionPrices'), 0);
        expect(
          logs.any((l) => l.contains('no pricing target for currency QQQ')),
          isTrue,
        );
        expect(
          logs.any((l) => l.contains('WARNING') && l.contains('XYZ')),
          isTrue,
        );
      },
    );

    test('re-runs skip territories already at the snapped point', () async {
      final client = FakeApiClient();
      final logs = <String>[];

      scriptExistingSubs(client);
      scriptAvailability(client, 's1', ['JPN']);
      scriptAvailability(client, 's2', ['USA']);
      scriptTerritories(client, {'JPN': 'JPY', 'USA': 'USD'});
      // JPN was priced on a previous run: the current point is the snapped
      // one (¥8500 for the ¥8700 target), which must be recognized by POINT
      // ID (the target price string never matches there).
      client.on(
        'GET',
        'v1/subscriptions/s1/prices',
        currentPrice('s1', 'pp-jpn-low', '8500'),
      );
      client.on(
        'GET',
        'v1/subscriptions/s1/pricePoints',
        ApiResponse(200, {
          'data': [
            _resource('subscriptionPricePoints', 'pp-jpn-low', {
              'customerPrice': '8500',
            }),
            _resource('subscriptionPricePoints', 'pp-jpn-high', {
              'customerPrice': '9000',
            }),
          ],
        }),
      );
      client.on(
        'GET',
        'v1/subscriptions/s2/prices',
        currentPrice('s2', 'pp-s2', '4.99'),
      );
      client.on(
        'GET',
        'v1/subscriptions/s2/pricePoints',
        pricePoints('pp-s2', '4.99'),
      );
      scriptExistingIap(client, '10417', '79.99');

      final provisioner = AscProvisioner(
        client: client,
        appId: '1234',
        log: logs.add,
      );
      final ok = await provisioner.run(
        subscriptions: subs,
        lifetimePriceUsd: '79.99',
      );

      expect(ok, isTrue);
      expect(client.count('POST', 'v1/subscriptionPrices'), 0);
      expect(
        logs.any((l) => l.contains('JPN: price already 8500 — skipping')),
        isTrue,
      );
      // The summary still lists the snapped territory.
      expect(logs.any((l) => l.contains('JPN→8500 (target 8700)')), isTrue);
    });

    test(
      'finds price points beyond the first page (cursor pagination)',
      () async {
        final client = FakeApiClient();
        final logs = <String>[];

        client.on(
          'POST',
          'v1/subscriptionGroups',
          ApiResponse(201, {'data': _resource('subscriptionGroups', 'g1')}),
        );
        client.on(
          'POST',
          'v1/subscriptions',
          ApiResponse(201, {'data': _resource('subscriptions', 's1')}),
        );
        client.on(
          'POST',
          'v1/subscriptions',
          ApiResponse(201, {'data': _resource('subscriptions', 's2')}),
        );
        scriptTerritories(client, {'USA': 'USD'}, times: 3);
        // Yearly's 49.99 point sits on page 2 (ASC USA has ~800 points,
        // paged at 200) — page 1 only holds points below the target.
        client.on(
          'GET',
          'v1/subscriptions/s1/pricePoints',
          ApiResponse(200, {
            'data': [
              _resource('subscriptionPricePoints', 'pp-y-early', {
                'customerPrice': '4.99',
              }),
            ],
            'meta': {
              'paging': {'total': 800, 'nextCursor': 'AMg', 'limit': 200},
            },
          }),
        );
        client.on(
          'GET',
          'v1/subscriptions/s1/pricePoints',
          pricePoints('pp-y', '49.99'),
        );
        client.on(
          'GET',
          'v1/subscriptions/s2/pricePoints',
          pricePoints('pp-m', '4.99'),
        );
        client.on(
          'POST',
          'v2/inAppPurchases',
          ApiResponse(201, {'data': _resource('inAppPurchases', 'i1')}),
        );
        client.on(
          'GET',
          'v2/inAppPurchases/i1/iapPriceSchedule',
          ApiResponse(404, null),
        );
        client.on(
          'GET',
          'v2/inAppPurchases/i1/pricePoints',
          ApiResponse(200, {
            'data': [
              _resource('inAppPurchasePricePoints', 'pp-l', {
                'customerPrice': '79.99',
              }),
            ],
          }),
        );

        final provisioner = AscProvisioner(
          client: client,
          appId: '1234',
          log: logs.add,
        );
        final ok = await provisioner.run(
          subscriptions: subs,
          lifetimePriceUsd: '79.99',
        );

        expect(ok, isTrue);
        final priceBodies = client.bodiesFor('POST', 'v1/subscriptionPrices');
        String pricePointOf(Map<String, Object?> body) =>
            ((((body['data'] as Map)['relationships']
                            as Map)['subscriptionPricePoint']
                        as Map)['data']
                    as Map)['id']
                as String;
        expect(pricePointOf(priceBodies[0]), 'pp-y');
        // The second request carried the cursor from page 1.
        expect(
          client.requests.any(
            (r) =>
                r.startsWith('GET v1/subscriptions/s1/pricePoints') &&
                r.contains('cursor=AMg'),
          ),
          isTrue,
        );
      },
    );

    test('a failing price POST is reported and the run continues', () async {
      final client = FakeApiClient();
      final logs = <String>[];

      client.on(
        'POST',
        'v1/subscriptionGroups',
        ApiResponse(201, {'data': _resource('subscriptionGroups', 'g1')}),
      );
      client.on(
        'POST',
        'v1/subscriptions',
        ApiResponse(201, {'data': _resource('subscriptions', 's1')}),
      );
      client.on(
        'POST',
        'v1/subscriptions',
        ApiResponse(201, {'data': _resource('subscriptions', 's2')}),
      );
      scriptTerritories(client, {'USA': 'USD'}, times: 3);
      client.on(
        'GET',
        'v1/subscriptions/s1/pricePoints',
        pricePoints('pp-s1', '49.99'),
      );
      client.on(
        'GET',
        'v1/subscriptions/s2/pricePoints',
        pricePoints('pp-s2', '4.99'),
      );
      // Every price POST 409s (account-level block, e.g. missing Paid Apps
      // agreement) — the run must still reach the IAP.
      client.onThrow(
        'POST',
        'v1/subscriptionPrices',
        ApiException(
          'POST',
          'https://x/v1/subscriptionPrices',
          409,
          'ENTITY_ERROR.RELATIONSHIP.INVALID',
        ),
      );
      client.onThrow(
        'POST',
        'v1/subscriptionPrices',
        ApiException(
          'POST',
          'https://x/v1/subscriptionPrices',
          409,
          'ENTITY_ERROR.RELATIONSHIP.INVALID',
        ),
      );
      client.on(
        'POST',
        'v2/inAppPurchases',
        ApiResponse(201, {'data': _resource('inAppPurchases', 'i1')}),
      );
      client.on(
        'GET',
        'v2/inAppPurchases/i1/iapPriceSchedule',
        ApiResponse(404, null),
      );
      client.on(
        'GET',
        'v2/inAppPurchases/i1/pricePoints',
        ApiResponse(200, {
          'data': [
            _resource('inAppPurchasePricePoints', 'pp-l', {
              'customerPrice': '79.99',
            }),
          ],
        }),
      );

      final provisioner = AscProvisioner(
        client: client,
        appId: '1234',
        log: logs.add,
      );
      final ok = await provisioner.run(
        subscriptions: subs,
        lifetimePriceUsd: '79.99',
      );

      expect(ok, isFalse);
      // Both subscription prices failed but the IAP was still fully done.
      expect(client.count('POST', 'v1/inAppPurchasePriceSchedules'), 1);
      expect(logs.where((l) => l.contains('Paid Apps')).length, 2);
    });

    test('creates a price change when the current price differs', () async {
      final client = FakeApiClient();
      final logs = <String>[];

      scriptExistingSubs(client);
      scriptAvailability(client, 's1', ['USA']);
      scriptAvailability(client, 's2', ['USA']);
      scriptTerritories(client, {'USA': 'USD'});
      // Yearly: current 24.99, wanted 49.99 → change. Monthly: matches.
      client.on(
        'GET',
        'v1/subscriptions/s1/prices',
        currentPrice('s1', 'pp-old', '24.99'),
      );
      client.on(
        'GET',
        'v1/subscriptions/s1/pricePoints',
        pricePoints('pp-new', '49.99'),
      );
      client.on(
        'GET',
        'v1/subscriptions/s2/prices',
        currentPrice('s2', 'pp-m', '4.99'),
      );
      client.on(
        'GET',
        'v1/subscriptions/s2/pricePoints',
        pricePoints('pp-m', '4.99'),
      );
      // IAP: schedule at tier 10417 (79.99), wanted 99.99 (tier 10477).
      scriptExistingIap(client, '10417', '79.99', scriptPricePoints: false);
      client.on(
        'GET',
        'v2/inAppPurchases/i1/pricePoints',
        ApiResponse(200, {
          'data': [
            _resource('inAppPurchasePricePoints', fakePointId('10477'), {
              'customerPrice': '99.99',
            }),
          ],
        }),
      );

      final provisioner = AscProvisioner(
        client: client,
        appId: '1234',
        log: logs.add,
      );
      final ok = await provisioner.run(
        subscriptions: subs,
        lifetimePriceUsd: '99.99',
      );

      expect(ok, isTrue);
      // Yearly got a price change with the new point; monthly was skipped.
      final priceBodies = client.bodiesFor('POST', 'v1/subscriptionPrices');
      expect(priceBodies, hasLength(1));
      expect(
        ((((priceBodies.first['data'] as Map)['relationships']
                    as Map)['subscriptionPricePoint']
                as Map)['data']
            as Map)['id'],
        'pp-new',
      );
      expect(
        logs.any((l) => l.contains('USA: set price 49.99 (was 24.99)')),
        isTrue,
      );
      // The IAP schedule was re-posted with the new point (create-or-replace).
      final scheduleBodies = client.bodiesFor(
        'POST',
        'v1/inAppPurchasePriceSchedules',
      );
      expect(scheduleBodies, hasLength(1));
      final included = scheduleBodies.first['included'] as List;
      expect(
        (((included.first as Map)['relationships']
                as Map)['inAppPurchasePricePoint']
            as Map)['data'],
        {'type': 'inAppPurchasePricePoints', 'id': fakePointId('10477')},
      );
      expect(logs.any((l) => l.contains('different price')), isTrue);
    });

    test(
      'schedules the price change when the subscription is already approved',
      () async {
        final client = FakeApiClient();
        final logs = <String>[];

        scriptExistingSubs(client);
        scriptAvailability(client, 's1', ['CAN']);
        scriptAvailability(client, 's2', ['USA']);
        scriptTerritories(client, {'CAN': 'CAD', 'USA': 'USD'});
        // CAN: current 24.99, wanted CAD 70.99 (Google table) — but the
        // subscription is approved, so the immediate price POST is rejected
        // and the change must be scheduled instead.
        client.on(
          'GET',
          'v1/subscriptions/s1/prices',
          currentPrice('s1', 'pp-old', '24.99'),
        );
        client.on(
          'GET',
          'v1/subscriptions/s1/pricePoints',
          pricePoints('pp-new', '70.99'),
        );
        client.onThrow(
          'POST',
          'v1/subscriptionPrices',
          ApiException(
            'POST',
            'https://x/v1/subscriptionPrices',
            409,
            'STATE_ERROR: Initial price cannot be created again after '
                'subscription is approved.',
          ),
        );
        client.on(
          'GET',
          'v1/subscriptions/s2/prices',
          currentPrice('s2', 'pp-m', '4.99'),
        );
        client.on(
          'GET',
          'v1/subscriptions/s2/pricePoints',
          pricePoints('pp-m', '4.99'),
        );
        scriptExistingIap(client, '10417', '79.99');

        final provisioner = AscProvisioner(
          client: client,
          appId: '1234',
          log: logs.add,
        );
        final ok = await provisioner.run(
          subscriptions: subs,
          lifetimePriceUsd: '79.99',
        );

        expect(ok, isTrue);
        // Two POSTs for CAN: the rejected immediate one, then the
        // scheduled one carrying a future startDate + grandfathering.
        final priceBodies = client.bodiesFor('POST', 'v1/subscriptionPrices');
        expect(priceBodies, hasLength(2));
        expect(
          (priceBodies[0]['data'] as Map).containsKey('attributes'),
          isFalse,
        );
        final scheduledAttrs =
            (priceBodies[1]['data'] as Map)['attributes'] as Map;
        final startDate = scheduledAttrs['startDate'] as String;
        expect(
          DateTime.parse(startDate).isAfter(DateTime.now().toUtc()),
          isTrue,
        );
        expect(scheduledAttrs['preserveCurrentPrice'], isTrue);
        expect(
          logs.any(
            (l) => l.contains(
              'CAN: scheduled price 70.99 starting $startDate (was 24.99)',
            ),
          ),
          isTrue,
        );
      },
    );

    test('skips a territory whose price change is already scheduled', () async {
      final client = FakeApiClient();
      final logs = <String>[];

      scriptExistingSubs(client);
      scriptAvailability(client, 's1', ['CAN']);
      scriptAvailability(client, 's2', ['USA']);
      scriptTerritories(client, {'CAN': 'CAD', 'USA': 'USD'});
      final futureDate = DateTime.now()
          .toUtc()
          .add(const Duration(days: 2))
          .toIso8601String()
          .substring(0, 10);
      // CAN: still at the old price, but a change to the wanted CAD 70.99
      // point is already scheduled — no new POST.
      client.on(
        'GET',
        'v1/subscriptions/s1/prices',
        priceWithScheduledChange(
          's1',
          'pp-old',
          '24.99',
          'pp-new',
          '70.99',
          futureDate,
        ),
      );
      client.on(
        'GET',
        'v1/subscriptions/s1/pricePoints',
        pricePoints('pp-new', '70.99'),
      );
      client.on(
        'GET',
        'v1/subscriptions/s2/prices',
        currentPrice('s2', 'pp-m', '4.99'),
      );
      client.on(
        'GET',
        'v1/subscriptions/s2/pricePoints',
        pricePoints('pp-m', '4.99'),
      );
      scriptExistingIap(client, '10417', '79.99');

      final provisioner = AscProvisioner(
        client: client,
        appId: '1234',
        log: logs.add,
      );
      final ok = await provisioner.run(
        subscriptions: subs,
        lifetimePriceUsd: '79.99',
      );

      expect(ok, isTrue);
      expect(client.count('POST', 'v1/subscriptionPrices'), 0);
      expect(
        logs.any(
          (l) => l.contains(
            'CAN: price change to 70.99 already scheduled '
            '(starts $futureDate) — skipping',
          ),
        ),
        isTrue,
      );
    });

    test('missing price points are skipped with a summary warning', () async {
      final client = FakeApiClient();
      final logs = <String>[];

      client.on(
        'POST',
        'v1/subscriptionGroups',
        ApiResponse(201, {'data': _resource('subscriptionGroups', 'g1')}),
      );
      client.on(
        'POST',
        'v1/subscriptions',
        ApiResponse(201, {'data': _resource('subscriptions', 's1')}),
      );
      client.on(
        'POST',
        'v1/subscriptions',
        ApiResponse(201, {'data': _resource('subscriptions', 's2')}),
      );
      scriptTerritories(client, {'USA': 'USD'}, times: 3);
      // No subscription price points scripted -> empty lists -> both
      // subscriptions skip USA and report it in a summary.
      client.on(
        'POST',
        'v2/inAppPurchases',
        ApiResponse(201, {'data': _resource('inAppPurchases', 'i1')}),
      );
      client.on(
        'GET',
        'v2/inAppPurchases/i1/iapPriceSchedule',
        ApiResponse(404, null),
      );
      client.on(
        'GET',
        'v2/inAppPurchases/i1/pricePoints',
        ApiResponse(200, {
          'data': [
            _resource('inAppPurchasePricePoints', 'pp-l', {
              'customerPrice': '79.99',
            }),
          ],
        }),
      );

      final provisioner = AscProvisioner(
        client: client,
        appId: '1234',
        log: logs.add,
      );
      final ok = await provisioner.run(
        subscriptions: subs,
        lifetimePriceUsd: '79.99',
      );

      // Not fatal: the run succeeds, no price POSTs happened, and each
      // subscription logged its skipped-territory summary.
      expect(ok, isTrue);
      expect(client.count('POST', 'v1/subscriptionPrices'), 0);
      expect(
        logs.where((l) => l.contains('WARNING') && l.contains('USA')).length,
        2,
      );
    });
  });
}
