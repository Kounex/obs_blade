import 'package:provisioning/src/asc_payloads.dart';
import 'package:test/test.dart';

void main() {
  group('subscriptionGroupCreate', () {
    test('matches SubscriptionGroupCreateRequest (spec 4.4.1)', () {
      final body = subscriptionGroupCreate(appId: '1234', referenceName: 'Pro');
      final data = body['data'] as Map<String, Object?>;
      expect(data['type'], 'subscriptionGroups');
      expect((data['attributes'] as Map)['referenceName'], 'Pro');
      final app = (data['relationships'] as Map)['app'] as Map;
      expect((app['data'] as Map)['type'], 'apps');
      expect((app['data'] as Map)['id'], '1234');
    });
  });

  group('subscriptionCreate', () {
    test('matches SubscriptionCreateRequest', () {
      final body = subscriptionCreate(
        groupId: 'g1',
        productId: 'pro_yearly',
        name: 'Pro - Yearly',
        subscriptionPeriod: 'ONE_YEAR',
      );
      final data = body['data'] as Map<String, Object?>;
      expect(data['type'], 'subscriptions');
      final attrs = data['attributes'] as Map;
      expect(attrs['productId'], 'pro_yearly');
      expect(attrs['subscriptionPeriod'], 'ONE_YEAR');
      expect(attrs['groupLevel'], 1);
      expect(attrs['familySharable'], false);
      final group = (data['relationships'] as Map)['group'] as Map;
      expect((group['data'] as Map)['type'], 'subscriptionGroups');
      expect((group['data'] as Map)['id'], 'g1');
    });
  });

  group('subscriptionLocalizationCreate', () {
    test('matches SubscriptionLocalizationCreateRequest', () {
      final body = subscriptionLocalizationCreate(
        subscriptionId: 's1',
        name: 'Pro - Yearly',
        description: 'Yearly Pro Subscription',
        locale: 'en-US',
      );
      final data = body['data'] as Map<String, Object?>;
      expect(data['type'], 'subscriptionLocalizations');
      final attrs = data['attributes'] as Map;
      expect(attrs['locale'], 'en-US');
      expect(attrs['name'], 'Pro - Yearly');
      expect(attrs['description'], 'Yearly Pro Subscription');
      final sub = (data['relationships'] as Map)['subscription'] as Map;
      expect((sub['data'] as Map)['id'], 's1');
    });
  });

  group('subscriptionLocalizationUpdate', () {
    test('PATCHes name + description with the resource id', () {
      final body = subscriptionLocalizationUpdate(
        id: 'l1',
        name: 'Pro - Yearly',
        description: 'Yearly Pro Subscription',
      );
      final data = body['data'] as Map<String, Object?>;
      expect(data['type'], 'subscriptionLocalizations');
      expect(data['id'], 'l1');
      expect(data['attributes'], {
        'name': 'Pro - Yearly',
        'description': 'Yearly Pro Subscription',
      });
      expect(data.containsKey('relationships'), isFalse);
    });
  });

  group('inAppPurchaseLocalizationUpdate', () {
    test('PATCHes name + description with the resource id', () {
      final body = inAppPurchaseLocalizationUpdate(
        id: 'il1',
        name: 'Pro - Lifetime',
        description: 'Lifetime Pro Access',
      );
      final data = body['data'] as Map<String, Object?>;
      expect(data['type'], 'inAppPurchaseLocalizations');
      expect(data['id'], 'il1');
      expect(data['attributes'], {
        'name': 'Pro - Lifetime',
        'description': 'Lifetime Pro Access',
      });
    });
  });

  group('inAppPurchaseCreate', () {
    test('matches InAppPurchaseV2CreateRequest', () {
      final body = inAppPurchaseCreate(
        appId: '1234',
        productId: 'pro_lifetime',
        name: 'Pro - Lifetime',
      );
      final data = body['data'] as Map<String, Object?>;
      expect(data['type'], 'inAppPurchases');
      final attrs = data['attributes'] as Map;
      expect(attrs['productId'], 'pro_lifetime');
      expect(attrs['inAppPurchaseType'], 'NON_CONSUMABLE');
    });
  });

  group('subscriptionPriceCreate', () {
    test('matches SubscriptionPriceCreateRequest', () {
      final body = subscriptionPriceCreate(
        subscriptionId: 's1',
        pricePointId: 'pp1',
        territoryId: 'USA',
      );
      final data = body['data'] as Map<String, Object?>;
      expect(data['type'], 'subscriptionPrices');
      final rels = data['relationships'] as Map;
      expect(((rels['subscription'] as Map)['data'] as Map)['id'], 's1');
      expect(
        ((rels['subscriptionPricePoint'] as Map)['data'] as Map)['id'],
        'pp1',
      );
      expect(((rels['territory'] as Map)['data'] as Map)['id'], 'USA');
    });
  });

  group('inAppPurchasePriceScheduleCreate', () {
    test('matches InAppPurchasePriceScheduleCreateRequest', () {
      final body = inAppPurchasePriceScheduleCreate(
        inAppPurchaseId: 'i1',
        pricePointId: 'pp9',
        baseTerritoryId: 'USA',
      );
      final data = body['data'] as Map<String, Object?>;
      expect(data['type'], 'inAppPurchasePriceSchedules');
      final rels = data['relationships'] as Map;
      expect(((rels['inAppPurchase'] as Map)['data'] as Map)['id'], 'i1');
      expect(((rels['baseTerritory'] as Map)['data'] as Map)['id'], 'USA');
      final manual = (rels['manualPrices'] as Map)['data'] as List;
      final tempId = (manual.single as Map)['id'];
      final included = body['included'] as List;
      final inline = included.single as Map;
      expect(inline['type'], 'inAppPurchasePrices');
      expect(inline['id'], tempId);
      expect(
        (((inline['relationships'] as Map)['inAppPurchasePricePoint']
                as Map)['data']
            as Map)['id'],
        'pp9',
      );
    });
  });
}
