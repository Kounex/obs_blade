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
      name: 'Pro — Yearly',
      subscriptionPeriod: 'ONE_YEAR',
      priceUsd: '24.99'),
  SubscriptionSpec(
      productId: 'pro_monthly',
      name: 'Pro — Monthly',
      subscriptionPeriod: 'ONE_MONTH',
      priceUsd: '4.99'),
];

Map<String, Object?> _resource(String type, String id,
        [Map<String, Object?> attributes = const {}]) =>
    {'type': type, 'id': id, 'attributes': attributes};

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
      // Territories list is fetched once per subscription (availability).
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
      // Creates: group, group loc, 2 subs, 2 sub locs, 2 sub prices,
      // IAP, IAP loc, IAP price schedule.
      expect(client.count('POST', 'v1/subscriptionGroups'), 1);
      expect(client.count('POST', 'v1/subscriptionGroupLocalizations'), 1);
      expect(client.count('POST', 'v1/subscriptions'), 2);
      expect(client.count('POST', 'v1/subscriptionLocalizations'), 2);
      expect(client.count('POST', 'v1/subscriptionPrices'), 2);
      expect(client.count('POST', 'v1/subscriptionAvailabilities'), 2);
      expect(client.count('POST', 'v2/inAppPurchases'), 1);
      expect(client.count('POST', 'v1/inAppPurchaseLocalizations'), 1);
      expect(client.count('POST', 'v1/inAppPurchasePriceSchedules'), 1);

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

      // Prices were attached to the right price points — yearly first,
      // then monthly (subscription spec order).
      final priceBodies = client.bodiesFor('POST', 'v1/subscriptionPrices');
      expect(priceBodies, hasLength(2));
      String pricePointOf(Map<String, Object?> body) =>
          ((((body['data'] as Map)['relationships'] as Map)[
                      'subscriptionPricePoint'] as Map)['data'] as Map)['id']
              as String;
      expect(pricePointOf(priceBodies[0]), 'pp-y');
      expect(pricePointOf(priceBodies[1]), 'pp-m');
    });

    test('is a no-op when everything already exists', () async {
      final client = FakeApiClient();
      final logs = <String>[];

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
      // Scripted twice: the group-subscriptions list is fetched once per
      // subscription spec (yearly + monthly).
      for (var i = 0; i < 2; i++) {
        client.on(
            'GET',
            'v1/subscriptionGroups/g1/subscriptions',
            ApiResponse(200, {
              'data': [
                _resource('subscriptions', 's1', {'productId': 'pro_yearly'}),
                _resource('subscriptions', 's2', {'productId': 'pro_monthly'}),
              ]
            }));
      }
      for (final s in ['s1', 's2']) {
        client.on(
            'GET',
            'v1/subscriptions/$s/subscriptionLocalizations',
            ApiResponse(200, {
              'data': [
                _resource(
                    'subscriptionLocalizations', 'l-$s', {'locale': 'en-US'})
              ]
            }));
        // Current price with its point included, matching the wanted price.
        client.on(
            'GET',
            'v1/subscriptions/$s/prices',
            ApiResponse(200, {
              'data': [
                {
                  'type': 'subscriptionPrices',
                  'id': 'p-$s',
                  'attributes': {'startDate': null},
                  'relationships': {
                    'subscriptionPricePoint': {
                      'data': {
                        'type': 'subscriptionPricePoints',
                        'id': 'pp-$s'
                      }
                    }
                  },
                }
              ],
              'included': [
                _resource('subscriptionPricePoints', 'pp-$s',
                    {'customerPrice': s == 's1' ? '24.99' : '4.99'})
              ],
            }));
        client.on(
            'GET',
            'v1/subscriptionAvailabilities/$s',
            ApiResponse(200, {
              'data': _resource('subscriptionAvailabilities', 'a-$s')
            }));
      }
      client.on(
          'GET',
          'v1/apps/1234/inAppPurchasesV2',
          ApiResponse(200, {
            'data': [
              _resource('inAppPurchases', 'i1', {'productId': 'pro_lifetime'})
            ]
          }));
      client.on(
          'GET',
          'v2/inAppPurchases/i1/inAppPurchaseLocalizations',
          ApiResponse(200, {
            'data': [
              _resource(
                  'inAppPurchaseLocalizations', 'il1', {'locale': 'en-US'})
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
                    {'type': 'inAppPurchasePrices', 'id': fakePointId('10417')}
                  ]
                }
              },
            }
          }));
      client.on(
          'GET',
          'v2/inAppPurchases/i1/pricePoints',
          ApiResponse(200, {
            'data': [
              _resource('inAppPurchasePricePoints', fakePointId('10417'),
                  {'customerPrice': '79.99'})
            ]
          }));

      final provisioner =
          AscProvisioner(client: client, appId: '1234', log: logs.add);
      final ok = await provisioner.run(
          subscriptions: subs, lifetimePriceUsd: '79.99');

      expect(ok, isTrue);
      expect(client.requests.where((r) => r.startsWith('POST')), isEmpty);
      expect(logs.where((l) => l.contains('already exists')).length,
          greaterThanOrEqualTo(6));
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
      for (final s in ['s1', 's2']) {
        client.on(
            'GET',
            'v1/subscriptions/$s/pricePoints',
            ApiResponse(200, {
              'data': [
                _resource('subscriptionPricePoints', 'pp-$s',
                    {'customerPrice': s == 's1' ? '24.99' : '4.99'})
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
                _resource('subscriptions', 's1', {'productId': 'pro_yearly'}),
                _resource('subscriptions', 's2', {'productId': 'pro_monthly'}),
              ]
            }));
      }
      for (final s in ['s1', 's2']) {
        client.on(
            'GET',
            'v1/subscriptions/$s/subscriptionLocalizations',
            ApiResponse(200, {
              'data': [
                _resource(
                    'subscriptionLocalizations', 'l-$s', {'locale': 'en-US'})
              ]
            }));
        client.on(
            'GET',
            'v1/subscriptionAvailabilities/$s',
            ApiResponse(200, {
              'data': _resource('subscriptionAvailabilities', 'a-$s')
            }));
      }
      // Yearly: current 24.99, wanted 49.99 → change. Monthly: matches.
      client.on(
          'GET',
          'v1/subscriptions/s1/prices',
          ApiResponse(200, {
            'data': [
              {
                'type': 'subscriptionPrices',
                'id': 'p-s1',
                'attributes': {'startDate': null},
                'relationships': {
                  'subscriptionPricePoint': {
                    'data': {'type': 'subscriptionPricePoints', 'id': 'pp-old'}
                  }
                },
              }
            ],
            'included': [
              _resource(
                  'subscriptionPricePoints', 'pp-old', {'customerPrice': '24.99'})
            ],
          }));
      client.on(
          'GET',
          'v1/subscriptions/s1/pricePoints',
          ApiResponse(200, {
            'data': [
              _resource('subscriptionPricePoints', 'pp-new',
                  {'customerPrice': '49.99'})
            ]
          }));
      client.on(
          'GET',
          'v1/subscriptions/s2/prices',
          ApiResponse(200, {
            'data': [
              {
                'type': 'subscriptionPrices',
                'id': 'p-s2',
                'attributes': {'startDate': null},
                'relationships': {
                  'subscriptionPricePoint': {
                    'data': {'type': 'subscriptionPricePoints', 'id': 'pp-m'}
                  }
                },
              }
            ],
            'included': [
              _resource(
                  'subscriptionPricePoints', 'pp-m', {'customerPrice': '4.99'})
            ],
          }));
      client.on(
          'GET',
          'v1/apps/1234/inAppPurchasesV2',
          ApiResponse(200, {
            'data': [
              _resource('inAppPurchases', 'i1', {'productId': 'pro_lifetime'})
            ]
          }));
      client.on(
          'GET',
          'v2/inAppPurchases/i1/inAppPurchaseLocalizations',
          ApiResponse(200, {
            'data': [
              _resource(
                  'inAppPurchaseLocalizations', 'il1', {'locale': 'en-US'})
            ]
          }));
      // IAP: schedule at tier 10417 (79.99), wanted 99.99 (tier 10477).
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
                    {'type': 'inAppPurchasePrices', 'id': fakePointId('10417')}
                  ]
                }
              },
            }
          }));
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
            name: 'Pro — Yearly',
            subscriptionPeriod: 'ONE_YEAR',
            priceUsd: '49.99'),
        SubscriptionSpec(
            productId: 'pro_monthly',
            name: 'Pro — Monthly',
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

    test('reports failure with console link when price point is missing',
        () async {
      final client = FakeApiClient();
      final logs = <String>[];

      client.on('POST', 'v1/subscriptionGroups',
          ApiResponse(201, {'data': _resource('subscriptionGroups', 'g1')}));
      client.on('POST', 'v1/subscriptions',
          ApiResponse(201, {'data': _resource('subscriptions', 's1')}));
      client.on('POST', 'v1/subscriptions',
          ApiResponse(201, {'data': _resource('subscriptions', 's2')}));
      // No price points scripted -> empty lists.
      client.on('POST', 'v2/inAppPurchases',
          ApiResponse(201, {'data': _resource('inAppPurchases', 'i1')}));
      client.on('GET', 'v2/inAppPurchases/i1/iapPriceSchedule',
          ApiResponse(404, null));

      final provisioner =
          AscProvisioner(client: client, appId: '1234', log: logs.add);
      final ok = await provisioner.run(
          subscriptions: subs, lifetimePriceUsd: '79.99');

      expect(ok, isFalse);
      expect(logs.any((l) => l.contains('appstoreconnect.apple.com')),
          isTrue);
    });
  });
}
