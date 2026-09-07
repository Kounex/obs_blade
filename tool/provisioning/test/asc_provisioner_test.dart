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
      priceUsd: '24.99'),
  SubscriptionSpec(
      productId: 'pro_monthly',
      name: 'Pro - Monthly',
      description: 'Monthly Pro Subscription',
      subscriptionPeriod: 'ONE_MONTH',
      priceUsd: '4.99'),
];

Map<String, Object?> _resource(String type, String id,
        [Map<String, Object?> attributes = const {}]) =>
    {'type': type, 'id': id, 'attributes': attributes};

/// Scripts an existing availability plus its territory list (the related
/// collection endpoint the provisioner reads territory ids from).
void scriptAvailability(
    FakeApiClient client, String subId, List<String> territories) {
  client.on(
      'GET',
      'v1/subscriptionAvailabilities/$subId',
      ApiResponse(200,
          {'data': _resource('subscriptionAvailabilities', 'a-$subId')}));
  client.on(
      'GET',
      'v1/subscriptionAvailabilities/$subId/availableTerritories',
      ApiResponse(200, {
        'data': [for (final t in territories) _resource('territories', t)]
      }));
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
              'data': {'type': 'subscriptionPricePoints', 'id': pointId}
            }
          },
        }
      ],
      'included': [
        _resource(
            'subscriptionPricePoints', pointId, {'customerPrice': customerPrice})
      ],
    });

/// Scripts the group + both subscriptions (+ localizations) as already
/// existing. Localization attributes default to the spec values (matching);
/// pass [s1LocAttributes] / [s2LocAttributes] to script drift.
void scriptExistingSubs(FakeApiClient client,
    {Map<String, Object?>? s1LocAttributes,
    Map<String, Object?>? s2LocAttributes,
    String? s1ReferenceName,
    String? s2ReferenceName}) {
  client.on(
      'GET',
      'v1/apps/1234/subscriptionGroups',
      ApiResponse(200, {
        'data': [
          _resource('subscriptionGroups', 'g1', {'referenceName': 'Pro'})
        ]
      }));
  client.on(
      'GET',
      'v1/subscriptionGroups/g1/subscriptionGroupLocalizations',
      ApiResponse(200, {
        'data': [
          _resource(
              'subscriptionGroupLocalizations', 'gl1', {'locale': 'en-US'})
        ]
      }));
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
          ]
        }));
  }
  final overrides = [s1LocAttributes, s2LocAttributes];
  for (var i = 0; i < 2; i++) {
    final spec = subs[i];
    client.on(
        'GET',
        'v1/subscriptions/s${i + 1}/subscriptionLocalizations',
        ApiResponse(200, {
          'data': [
            _resource('subscriptionLocalizations', 'l-s${i + 1}',
                overrides[i] ??
                    {
                      'locale': 'en-US',
                      'name': spec.name,
                      'description': spec.description,
                    })
          ]
        }));
  }
}

/// Scripts the IAP (+ localization) as already existing, with its price
/// schedule already at [tier] and — unless [scriptPricePoints] is false —
/// the matching point available. [iapLocAttributes] overrides the
/// (default: matching) localization attributes.
void scriptExistingIap(FakeApiClient client, String tier, String price,
    {Map<String, Object?>? iapLocAttributes,
    bool scriptPricePoints = true,
    String? iapReferenceName}) {
  client.on(
      'GET',
      'v1/apps/1234/inAppPurchasesV2',
      ApiResponse(200, {
        'data': [
          _resource('inAppPurchases', 'i1', {
            'productId': 'pro_lifetime',
            'name': iapReferenceName ?? AscProvisioner.lifetimeName,
          })
        ]
      }));
  client.on(
      'GET',
      'v2/inAppPurchases/i1/inAppPurchaseLocalizations',
      ApiResponse(200, {
        'data': [
          _resource('inAppPurchaseLocalizations', 'il1',
              iapLocAttributes ??
                  {
                    'locale': 'en-US',
                    'name': AscProvisioner.lifetimeName,
                    'description': AscProvisioner.lifetimeDescription,
                  })
        ]
      }));
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
                {'type': 'inAppPurchasePrices', 'id': fakePointId(tier)}
              ]
            }
          },
        }
      }));
  if (scriptPricePoints) {
    client.on(
        'GET',
        'v2/inAppPurchases/i1/pricePoints',
        ApiResponse(200, {
          'data': [
            _resource('inAppPurchasePricePoints', fakePointId(tier),
                {'customerPrice': price})
          ]
        }));
  }
}

void main() {
  group('AscProvisioner', () {
    test('creates everything when nothing exists', () async {
      final client = FakeApiClient();
      final logs = <String>[];

      client.on('POST', 'v1/subscriptionGroups',
          ApiResponse(201, {'data': _resource('subscriptionGroups', 'g1')}));
      // subscriptions are created in order: yearly -> s1, monthly -> s2
      client.on('POST', 'v1/subscriptions',
          ApiResponse(201, {'data': _resource('subscriptions', 's1')}));
      client.on('POST', 'v1/subscriptions',
          ApiResponse(201, {'data': _resource('subscriptions', 's2')}));
      // Territories list is fetched once per subscription (availability is
      // created over all of them, then each territory gets priced).
      for (var i = 0; i < 2; i++) {
        client.on(
            'GET',
            'v1/territories',
            ApiResponse(200, {
              'data': [
                _resource('territories', 'USA'),
                _resource('territories', 'DEU'),
              ]
            }));
      }
      // Price points are looked up once per territory (USA, then DEU).
      for (var i = 0; i < 2; i++) {
        client.on(
            'GET',
            'v1/subscriptions/s1/pricePoints',
            ApiResponse(200, {
              'data': [
                _resource('subscriptionPricePoints', 'pp-y',
                    {'customerPrice': '24.99'})
              ]
            }));
        client.on(
            'GET',
            'v1/subscriptions/s2/pricePoints',
            ApiResponse(200, {
              'data': [
                _resource('subscriptionPricePoints', 'pp-m',
                    {'customerPrice': '4.99'})
              ]
            }));
      }
      client.on('POST', 'v2/inAppPurchases',
          ApiResponse(201, {'data': _resource('inAppPurchases', 'i1')}));
      client.on('GET', 'v2/inAppPurchases/i1/iapPriceSchedule',
          ApiResponse(404, null));
      client.on(
          'GET',
          'v2/inAppPurchases/i1/pricePoints',
          ApiResponse(200, {
            'data': [
              _resource(
                  'inAppPurchasePricePoints', 'pp-l', {'customerPrice': '79.99'})
            ]
          }));

      final provisioner =
          AscProvisioner(client: client, appId: '1234', log: logs.add);
      final ok = await provisioner.run(
          subscriptions: subs, lifetimePriceUsd: '79.99');

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
      final locBodies =
          client.bodiesFor('POST', 'v1/subscriptionLocalizations');
      expect(
          ((locBodies.first['data'] as Map)['attributes'] as Map)['name'],
          'Pro - Yearly');
      expect(
          ((locBodies.first['data'] as Map)['attributes'] as Map)
              ['description'],
          'Yearly Pro Subscription');

      // Availability covers all listed territories plus future ones.
      final availabilityBodies =
          client.bodiesFor('POST', 'v1/subscriptionAvailabilities');
      final availabilityData =
          (availabilityBodies.first['data'] as Map)['relationships'] as Map;
      final territoryData = (availabilityData['availableTerritories']
          as Map)['data'] as List;
      expect(territoryData.map((t) => (t as Map)['id']), ['USA', 'DEU']);
      expect(
          ((availabilityBodies.first['data'] as Map)['attributes']
              as Map)['availableInNewTerritories'],
          isTrue);

      // Prices were attached to the right price points per territory —
      // yearly USA/DEU first, then monthly USA/DEU (spec order).
      final priceBodies = client.bodiesFor('POST', 'v1/subscriptionPrices');
      expect(priceBodies, hasLength(4));
      String pointOf(Map<String, Object?> body) =>
          ((((body['data'] as Map)['relationships'] as Map)[
                      'subscriptionPricePoint'] as Map)['data'] as Map)['id']
              as String;
      String territoryOf(Map<String, Object?> body) =>
          ((((body['data'] as Map)['relationships'] as Map)['territory']
              as Map)['data'] as Map)['id'] as String;
      expect(priceBodies.map(pointOf), ['pp-y', 'pp-y', 'pp-m', 'pp-m']);
      expect(
          priceBodies.map(territoryOf), ['USA', 'DEU', 'USA', 'DEU']);
    });

    test('is a no-op when everything already exists', () async {
      final client = FakeApiClient();
      final logs = <String>[];

      scriptExistingSubs(client);
      scriptAvailability(client, 's1', ['USA']);
      scriptAvailability(client, 's2', ['USA']);
      client.on('GET', 'v1/subscriptions/s1/prices',
          currentPrice('s1', 'pp-s1', '24.99'));
      client.on('GET', 'v1/subscriptions/s2/prices',
          currentPrice('s2', 'pp-s2', '4.99'));
      scriptExistingIap(client, '10417', '79.99');

      final provisioner =
          AscProvisioner(client: client, appId: '1234', log: logs.add);
      final ok = await provisioner.run(
          subscriptions: subs, lifetimePriceUsd: '79.99');

      expect(ok, isTrue);
      expect(client.requests.where((r) => r.startsWith('POST')), isEmpty);
      expect(client.requests.where((r) => r.startsWith('PATCH')), isEmpty);
      expect(logs.where((l) => l.contains('already')).length,
          greaterThanOrEqualTo(8));
    });

    test('PATCHes drifted localizations instead of re-creating them',
        () async {
      final client = FakeApiClient();
      final logs = <String>[];

      scriptExistingSubs(client, s1LocAttributes: {
        'locale': 'en-US',
        'name': 'Pro — Yearly',
        'description': '',
      });
      scriptAvailability(client, 's1', ['USA']);
      scriptAvailability(client, 's2', ['USA']);
      client.on('GET', 'v1/subscriptions/s1/prices',
          currentPrice('s1', 'pp-s1', '24.99'));
      client.on('GET', 'v1/subscriptions/s2/prices',
          currentPrice('s2', 'pp-s2', '4.99'));
      // IAP localization drifted too (em-dash name, no description).
      scriptExistingIap(client, '10417', '79.99', iapLocAttributes: {
        'locale': 'en-US',
        'name': 'Pro — Lifetime',
      });

      final provisioner =
          AscProvisioner(client: client, appId: '1234', log: logs.add);
      final ok = await provisioner.run(
          subscriptions: subs, lifetimePriceUsd: '79.99');

      expect(ok, isTrue);
      expect(client.count('POST', 'v1/subscriptionLocalizations'), 0);
      expect(client.count('POST', 'v1/inAppPurchaseLocalizations'), 0);

      final subPatch =
          client.bodiesFor('PATCH', 'v1/subscriptionLocalizations/l-s1');
      expect(subPatch, hasLength(1));
      final subAttrs =
          (subPatch.single['data'] as Map)['attributes'] as Map;
      expect(subAttrs['name'], 'Pro - Yearly');
      expect(subAttrs['description'], 'Yearly Pro Subscription');
      expect((subPatch.single['data'] as Map)['type'],
          'subscriptionLocalizations');

      final iapPatch =
          client.bodiesFor('PATCH', 'v1/inAppPurchaseLocalizations/il1');
      expect(iapPatch, hasLength(1));
      final iapAttrs =
          (iapPatch.single['data'] as Map)['attributes'] as Map;
      expect(iapAttrs['name'], 'Pro - Lifetime');
      expect(iapAttrs['description'], 'Lifetime Pro Access');
      expect(logs.where((l) => l.contains('drifted')).length, 2);
    });

    test('PATCHes drifted reference names (subscriptions + IAP)', () async {
      final client = FakeApiClient();
      final logs = <String>[];

      scriptExistingSubs(client,
          s1ReferenceName: 'Pro — Yearly', s2ReferenceName: 'Pro — Monthly');
      scriptAvailability(client, 's1', ['USA']);
      scriptAvailability(client, 's2', ['USA']);
      client.on('GET', 'v1/subscriptions/s1/prices',
          currentPrice('s1', 'pp-s1', '24.99'));
      client.on('GET', 'v1/subscriptions/s2/prices',
          currentPrice('s2', 'pp-s2', '4.99'));
      scriptExistingIap(client, '10417', '79.99',
          iapReferenceName: 'Pro — Lifetime');

      final provisioner =
          AscProvisioner(client: client, appId: '1234', log: logs.add);
      final ok = await provisioner.run(
          subscriptions: subs, lifetimePriceUsd: '79.99');

      expect(ok, isTrue);
      final s1Patch = client.bodiesFor('PATCH', 'v1/subscriptions/s1');
      expect(s1Patch, hasLength(1));
      expect(((s1Patch.single['data'] as Map)['attributes'] as Map)['name'],
          'Pro - Yearly');
      expect((s1Patch.single['data'] as Map)['type'], 'subscriptions');
      expect(
          client.bodiesFor('PATCH', 'v1/subscriptions/s2'), hasLength(1));
      final iapPatch = client.bodiesFor('PATCH', 'v2/inAppPurchases/i1');
      expect(iapPatch, hasLength(1));
      expect(((iapPatch.single['data'] as Map)['attributes'] as Map)['name'],
          'Pro - Lifetime');
      expect((iapPatch.single['data'] as Map)['type'], 'inAppPurchases');
      // Localizations match (fixtures default to spec values) — no
      // localization PATCHes.
      expect(
          client.requests.where((r) => r.contains('Localizations') &&
              r.startsWith('PATCH')),
          isEmpty);
    });

    test('prices every territory with nominal parity, skips matching ones',
        () async {
      final client = FakeApiClient();
      final logs = <String>[];

      scriptExistingSubs(client);
      // USA already at parity, DEU unpriced (point exists), JPN unpriced
      // with no 24.99 point — page 1 jumps past the target (sorted
      // ascending) so the scan must stop early and skip JPN.
      scriptAvailability(client, 's1', ['USA', 'DEU', 'JPN']);
      scriptAvailability(client, 's2', ['USA']);
      client.on('GET', 'v1/subscriptions/s1/prices',
          currentPrice('s1', 'pp-usa', '24.99'));
      client.on('GET', 'v1/subscriptions/s2/prices',
          currentPrice('s2', 'pp-s2', '4.99'));
      client.on(
          'GET',
          'v1/subscriptions/s1/pricePoints',
          ApiResponse(200, {
            'data': [
              _resource('subscriptionPricePoints', 'pp-deu',
                  {'customerPrice': '24.99'})
            ]
          }));
      client.on(
          'GET',
          'v1/subscriptions/s1/pricePoints',
          ApiResponse(200, {
            'data': [
              _resource('subscriptionPricePoints', 'pp-jpn-low',
                  {'customerPrice': '0.29'}),
              _resource('subscriptionPricePoints', 'pp-jpn-high',
                  {'customerPrice': '25'})
            ],
            'meta': {
              'paging': {'total': 800, 'nextCursor': 'AMg', 'limit': 200}
            },
          }));
      scriptExistingIap(client, '10417', '79.99');

      final provisioner =
          AscProvisioner(client: client, appId: '1234', log: logs.add);
      final ok = await provisioner.run(
          subscriptions: subs, lifetimePriceUsd: '79.99');

      expect(ok, isTrue); // missing points don't fail the run
      final priceBodies = client.bodiesFor('POST', 'v1/subscriptionPrices');
      expect(priceBodies, hasLength(1)); // only DEU
      final rels = (priceBodies.single['data'] as Map)['relationships'] as Map;
      expect(((rels['territory'] as Map)['data'] as Map)['id'], 'DEU');
      expect(((rels['subscriptionPricePoint'] as Map)['data'] as Map)['id'],
          'pp-deu');
      // JPN was skipped with a summary warning, and the cursor was NOT
      // followed (early exit once a point exceeds the target).
      expect(
          logs.any((l) => l.contains('WARNING') && l.contains('JPN')), isTrue);
      expect(client.requests.any((r) => r.contains('cursor=AMg')), isFalse);
    });

    test('finds price points beyond the first page (cursor pagination)',
        () async {
      final client = FakeApiClient();
      final logs = <String>[];

      client.on('POST', 'v1/subscriptionGroups',
          ApiResponse(201, {'data': _resource('subscriptionGroups', 'g1')}));
      client.on('POST', 'v1/subscriptions',
          ApiResponse(201, {'data': _resource('subscriptions', 's1')}));
      client.on('POST', 'v1/subscriptions',
          ApiResponse(201, {'data': _resource('subscriptions', 's2')}));
      for (var i = 0; i < 2; i++) {
        client.on(
            'GET',
            'v1/territories',
            ApiResponse(200, {
              'data': [_resource('territories', 'USA')]
            }));
      }
      // Yearly's 24.99 point sits on page 2 of 4 (ASC USA has ~800 points,
      // paged at 200) — page 1 must not satisfy the lookup.
      client.on(
          'GET',
          'v1/subscriptions/s1/pricePoints',
          ApiResponse(200, {
            'data': [
              _resource('subscriptionPricePoints', 'pp-y-early',
                  {'customerPrice': '4.99'})
            ],
            'meta': {
              'paging': {'total': 800, 'nextCursor': 'AMg', 'limit': 200}
            },
          }));
      client.on(
          'GET',
          'v1/subscriptions/s1/pricePoints',
          ApiResponse(200, {
            'data': [
              _resource('subscriptionPricePoints', 'pp-y',
                  {'customerPrice': '24.99'})
            ],
          }));
      client.on(
          'GET',
          'v1/subscriptions/s2/pricePoints',
          ApiResponse(200, {
            'data': [
              _resource('subscriptionPricePoints', 'pp-m',
                  {'customerPrice': '4.99'})
            ]
          }));
      client.on('POST', 'v2/inAppPurchases',
          ApiResponse(201, {'data': _resource('inAppPurchases', 'i1')}));
      client.on('GET', 'v2/inAppPurchases/i1/iapPriceSchedule',
          ApiResponse(404, null));
      client.on(
          'GET',
          'v2/inAppPurchases/i1/pricePoints',
          ApiResponse(200, {
            'data': [
              _resource(
                  'inAppPurchasePricePoints', 'pp-l', {'customerPrice': '79.99'})
            ]
          }));

      final provisioner =
          AscProvisioner(client: client, appId: '1234', log: logs.add);
      final ok = await provisioner.run(
          subscriptions: subs, lifetimePriceUsd: '79.99');

      expect(ok, isTrue);
      final priceBodies = client.bodiesFor('POST', 'v1/subscriptionPrices');
      String pricePointOf(Map<String, Object?> body) =>
          ((((body['data'] as Map)['relationships'] as Map)[
                      'subscriptionPricePoint'] as Map)['data'] as Map)['id']
              as String;
      expect(pricePointOf(priceBodies[0]), 'pp-y');
      // The second request carried the cursor from page 1.
      expect(
          client.requests.any((r) =>
              r.startsWith('GET v1/subscriptions/s1/pricePoints') &&
              r.contains('cursor=AMg')),
          isTrue);
    });

    test('a failing price POST is reported and the run continues', () async {
      final client = FakeApiClient();
      final logs = <String>[];

      client.on('POST', 'v1/subscriptionGroups',
          ApiResponse(201, {'data': _resource('subscriptionGroups', 'g1')}));
      client.on('POST', 'v1/subscriptions',
          ApiResponse(201, {'data': _resource('subscriptions', 's1')}));
      client.on('POST', 'v1/subscriptions',
          ApiResponse(201, {'data': _resource('subscriptions', 's2')}));
      for (var i = 0; i < 2; i++) {
        client.on(
            'GET',
            'v1/territories',
            ApiResponse(200, {
              'data': [_resource('territories', 'USA')]
            }));
        client.on(
            'GET',
            'v1/subscriptions/${i == 0 ? 's1' : 's2'}/pricePoints',
            ApiResponse(200, {
              'data': [
                _resource('subscriptionPricePoints', 'pp-s${i + 1}',
                    {'customerPrice': i == 0 ? '24.99' : '4.99'})
              ]
            }));
      }
      // Every price POST 409s (account-level block, e.g. missing Paid Apps
      // agreement) — the run must still reach the IAP.
      client.onThrow(
          'POST',
          'v1/subscriptionPrices',
          ApiException('POST', 'https://x/v1/subscriptionPrices', 409,
              'ENTITY_ERROR.RELATIONSHIP.INVALID'));
      client.onThrow(
          'POST',
          'v1/subscriptionPrices',
          ApiException('POST', 'https://x/v1/subscriptionPrices', 409,
              'ENTITY_ERROR.RELATIONSHIP.INVALID'));
      client.on('POST', 'v2/inAppPurchases',
          ApiResponse(201, {'data': _resource('inAppPurchases', 'i1')}));
      client.on('GET', 'v2/inAppPurchases/i1/iapPriceSchedule',
          ApiResponse(404, null));
      client.on(
          'GET',
          'v2/inAppPurchases/i1/pricePoints',
          ApiResponse(200, {
            'data': [
              _resource(
                  'inAppPurchasePricePoints', 'pp-l', {'customerPrice': '79.99'})
            ]
          }));

      final provisioner =
          AscProvisioner(client: client, appId: '1234', log: logs.add);
      final ok = await provisioner.run(
          subscriptions: subs, lifetimePriceUsd: '79.99');

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
      // Yearly: current 24.99, wanted 49.99 → change. Monthly: matches.
      client.on('GET', 'v1/subscriptions/s1/prices',
          currentPrice('s1', 'pp-old', '24.99'));
      client.on(
          'GET',
          'v1/subscriptions/s1/pricePoints',
          ApiResponse(200, {
            'data': [
              _resource('subscriptionPricePoints', 'pp-new',
                  {'customerPrice': '49.99'})
            ]
          }));
      client.on('GET', 'v1/subscriptions/s2/prices',
          currentPrice('s2', 'pp-m', '4.99'));
      // IAP: schedule at tier 10417 (79.99), wanted 99.99 (tier 10477).
      scriptExistingIap(client, '10417', '79.99', scriptPricePoints: false);
      client.on(
          'GET',
          'v2/inAppPurchases/i1/pricePoints',
          ApiResponse(200, {
            'data': [
              _resource('inAppPurchasePricePoints', fakePointId('10477'),
                  {'customerPrice': '99.99'})
            ]
          }));

      const updatedSubs = [
        SubscriptionSpec(
            productId: 'pro_yearly',
            name: 'Pro - Yearly',
            description: 'Yearly Pro Subscription',
            subscriptionPeriod: 'ONE_YEAR',
            priceUsd: '49.99'),
        SubscriptionSpec(
            productId: 'pro_monthly',
            name: 'Pro - Monthly',
            description: 'Monthly Pro Subscription',
            subscriptionPeriod: 'ONE_MONTH',
            priceUsd: '4.99'),
      ];
      final provisioner =
          AscProvisioner(client: client, appId: '1234', log: logs.add);
      final ok = await provisioner.run(
          subscriptions: updatedSubs, lifetimePriceUsd: '99.99');

      expect(ok, isTrue);
      // Yearly got a price change with the new point; monthly was skipped.
      final priceBodies = client.bodiesFor('POST', 'v1/subscriptionPrices');
      expect(priceBodies, hasLength(1));
      expect(
          ((((priceBodies.first['data'] as Map)['relationships'] as Map)[
                      'subscriptionPricePoint'] as Map)['data'] as Map)['id'],
          'pp-new');
      // The IAP schedule was re-posted with the new point (create-or-replace).
      final scheduleBodies =
          client.bodiesFor('POST', 'v1/inAppPurchasePriceSchedules');
      expect(scheduleBodies, hasLength(1));
      final included = scheduleBodies.first['included'] as List;
      expect(
          (((included.first as Map)['relationships']
                      as Map)['inAppPurchasePricePoint'] as Map)['data'],
          {'type': 'inAppPurchasePricePoints', 'id': fakePointId('10477')});
      expect(logs.any((l) => l.contains('price differs')), isTrue);
      expect(logs.any((l) => l.contains('different price')), isTrue);
    });

    test('missing price points are skipped with a summary warning', () async {
      final client = FakeApiClient();
      final logs = <String>[];

      client.on('POST', 'v1/subscriptionGroups',
          ApiResponse(201, {'data': _resource('subscriptionGroups', 'g1')}));
      client.on('POST', 'v1/subscriptions',
          ApiResponse(201, {'data': _resource('subscriptions', 's1')}));
      client.on('POST', 'v1/subscriptions',
          ApiResponse(201, {'data': _resource('subscriptions', 's2')}));
      for (var i = 0; i < 2; i++) {
        client.on(
            'GET',
            'v1/territories',
            ApiResponse(200, {
              'data': [_resource('territories', 'USA')]
            }));
      }
      // No subscription price points scripted -> empty lists -> both
      // subscriptions skip USA and report it in a summary.
      client.on('POST', 'v2/inAppPurchases',
          ApiResponse(201, {'data': _resource('inAppPurchases', 'i1')}));
      client.on('GET', 'v2/inAppPurchases/i1/iapPriceSchedule',
          ApiResponse(404, null));
      client.on(
          'GET',
          'v2/inAppPurchases/i1/pricePoints',
          ApiResponse(200, {
            'data': [
              _resource(
                  'inAppPurchasePricePoints', 'pp-l', {'customerPrice': '79.99'})
            ]
          }));

      final provisioner =
          AscProvisioner(client: client, appId: '1234', log: logs.add);
      final ok = await provisioner.run(
          subscriptions: subs, lifetimePriceUsd: '79.99');

      // Not fatal: the run succeeds, no price POSTs happened, and each
      // subscription logged its skipped-territory summary.
      expect(ok, isTrue);
      expect(client.count('POST', 'v1/subscriptionPrices'), 0);
      expect(
          logs.where((l) => l.contains('WARNING') && l.contains('USA')).length,
          2);
    });
  });
}
