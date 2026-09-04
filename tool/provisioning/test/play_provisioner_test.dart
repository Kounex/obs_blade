import 'package:provisioning/src/api_client.dart';
import 'package:provisioning/src/play_payloads.dart';
import 'package:provisioning/src/play_provisioner.dart';
import 'package:test/test.dart';

import 'fake_api_client.dart';

const pkg = 'com.kounex.obsBlade';
const basePlans = [
  BasePlanSpec(
      basePlanId: 'pro-yearly',
      billingPeriodDuration: 'P1Y',
      priceUsd: '24.99'),
  BasePlanSpec(
      basePlanId: 'pro-monthly',
      billingPeriodDuration: 'P1M',
      priceUsd: '4.99'),
];

Map<String, Object?> _subscription(List<Map<String, Object?>> plans) => {
      'productId': 'pro',
      'packageName': pkg,
      'basePlans': plans,
    };

void main() {
  group('PlayProvisioner', () {
    test('creates and activates everything when nothing exists', () async {
      final client = FakeApiClient();
      final logs = <String>[];

      // Subscription GET -> 404 (missing); after create the re-read shows
      // the two base plans in DRAFT.
      client.on('GET', 'androidpublisher/v3/applications/$pkg/subscriptions/pro',
          ApiResponse(404, null));
      client.on('GET', 'androidpublisher/v3/applications/$pkg/subscriptions/pro',
          ApiResponse(200, _subscription([
            {'basePlanId': 'pro-yearly', 'state': 'DRAFT'},
            {'basePlanId': 'pro-monthly', 'state': 'DRAFT'},
          ])));
      // One-time product: GET 404, batchUpdate creates, re-read DRAFT.
      client.on(
          'GET', 'androidpublisher/v3/applications/$pkg/oneTimeProducts/pro_lifetime',
          ApiResponse(404, null));
      client.on(
          'GET', 'androidpublisher/v3/applications/$pkg/oneTimeProducts/pro_lifetime',
          ApiResponse(200, {
            'productId': 'pro_lifetime',
            'purchaseOptions': [
              {'purchaseOptionId': 'pro-lifetime', 'state': 'DRAFT'}
            ],
          }));

      final provisioner = PlayProvisioner(
          client: client, packageName: pkg, log: logs.add);
      final ok = await provisioner.run(
          basePlans: basePlans, lifetimePriceUsd: '79.99');

      expect(ok, isTrue);
      expect(client.count('POST',
          'androidpublisher/v3/applications/$pkg/subscriptions'), 1);
      expect(
          client.count(
              'POST',
              'androidpublisher/v3/applications/$pkg/subscriptions/pro/'
              'basePlans/pro-yearly:activate'),
          1);
      expect(
          client.count(
              'POST',
              'androidpublisher/v3/applications/$pkg/subscriptions/pro/'
              'basePlans/pro-monthly:activate'),
          1);
      expect(
          client.count('POST',
              'androidpublisher/v3/applications/$pkg/oneTimeProducts:batchUpdate'),
          1);
      expect(
          client.count(
              'POST',
              'androidpublisher/v3/applications/$pkg/oneTimeProducts/'
              'pro_lifetime/purchaseOptions:batchUpdateStates'),
          1);
    });

    test('is a no-op when everything already exists and is active', () async {
      final client = FakeApiClient();
      final logs = <String>[];

      // Scripted twice: once for the existence/base-plan check, once for
      // the post-create state re-read.
      for (var i = 0; i < 2; i++) {
        client.on(
            'GET', 'androidpublisher/v3/applications/$pkg/subscriptions/pro',
            ApiResponse(200, _subscription([
              {'basePlanId': 'pro-yearly', 'state': 'ACTIVE'},
              {'basePlanId': 'pro-monthly', 'state': 'ACTIVE'},
            ])));
      }
      client.on(
          'GET', 'androidpublisher/v3/applications/$pkg/oneTimeProducts/pro_lifetime',
          ApiResponse(200, {
            'productId': 'pro_lifetime',
            'purchaseOptions': [
              {'purchaseOptionId': 'pro-lifetime', 'state': 'ACTIVE'}
            ],
          }));

      final provisioner = PlayProvisioner(
          client: client, packageName: pkg, log: logs.add);
      final ok = await provisioner.run(
          basePlans: basePlans, lifetimePriceUsd: '79.99');

      expect(ok, isTrue);
      expect(client.requests.where((r) => r.startsWith('POST')), isEmpty);
      expect(logs.any((l) => l.contains('already exists')), isTrue);
      expect(logs.any((l) => l.contains('already ACTIVE')), isTrue);
    });

    test('patches in a missing base plan on an existing subscription',
        () async {
      final client = FakeApiClient();
      final logs = <String>[];

      client.on('GET', 'androidpublisher/v3/applications/$pkg/subscriptions/pro',
          ApiResponse(200, _subscription([
            {'basePlanId': 'pro-yearly', 'state': 'ACTIVE'},
          ])));
      // Re-read after patch: both plans, monthly still DRAFT.
      client.on('GET', 'androidpublisher/v3/applications/$pkg/subscriptions/pro',
          ApiResponse(200, _subscription([
            {'basePlanId': 'pro-yearly', 'state': 'ACTIVE'},
            {'basePlanId': 'pro-monthly', 'state': 'DRAFT'},
          ])));
      client.on(
          'GET', 'androidpublisher/v3/applications/$pkg/oneTimeProducts/pro_lifetime',
          ApiResponse(200, {
            'productId': 'pro_lifetime',
            'purchaseOptions': [
              {'purchaseOptionId': 'pro-lifetime', 'state': 'ACTIVE'}
            ],
          }));

      final provisioner = PlayProvisioner(
          client: client, packageName: pkg, log: logs.add);
      final ok = await provisioner.run(
          basePlans: basePlans, lifetimePriceUsd: '79.99');

      expect(ok, isTrue);
      expect(client.count('PATCH',
          'androidpublisher/v3/applications/$pkg/subscriptions/pro'), 1);
      expect(
          client.count(
              'POST',
              'androidpublisher/v3/applications/$pkg/subscriptions/pro/'
              'basePlans/pro-monthly:activate'),
          1);
      expect(
          client.count(
              'POST',
              'androidpublisher/v3/applications/$pkg/subscriptions/pro/'
              'basePlans/pro-yearly:activate'),
          0,
          reason: 'already-active base plan must not be re-activated');
    });
  });
}
