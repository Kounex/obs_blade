/// Pure request-body builders for the App Store Connect API calls the
/// asc-products command makes. Field names verified against Apple's
/// official OpenAPI spec (app-store-connect-openapi-specification, v4.4.1).
library;

/// Relationship member helper: `{data: {type: t, id: id}}`.
Map<String, Object?> rel(String type, String id) => {
      'data': {'type': type, 'id': id}
    };

/// POST /v1/subscriptionGroups — SubscriptionGroupCreateRequest.
Map<String, Object?> subscriptionGroupCreate({
  required String appId,
  required String referenceName,
}) =>
    {
      'data': {
        'type': 'subscriptionGroups',
        'attributes': {'referenceName': referenceName},
        'relationships': {'app': rel('apps', appId)},
      }
    };

/// POST /v1/subscriptionGroupLocalizations.
Map<String, Object?> subscriptionGroupLocalizationCreate({
  required String groupId,
  required String name,
  required String locale,
}) =>
    {
      'data': {
        'type': 'subscriptionGroupLocalizations',
        'attributes': {'name': name, 'locale': locale},
        'relationships': {'subscriptionGroup': rel('subscriptionGroups', groupId)},
      }
    };

/// POST /v1/subscriptions — SubscriptionCreateRequest.
Map<String, Object?> subscriptionCreate({
  required String groupId,
  required String productId,
  required String name,
  required String subscriptionPeriod, // ONE_MONTH / ONE_YEAR / ...
  int groupLevel = 1,
  bool familySharable = false,
}) =>
    {
      'data': {
        'type': 'subscriptions',
        'attributes': {
          'productId': productId,
          'name': name,
          'subscriptionPeriod': subscriptionPeriod,
          'groupLevel': groupLevel,
          'familySharable': familySharable,
        },
        'relationships': {'group': rel('subscriptionGroups', groupId)},
      }
    };

/// POST /v1/subscriptionLocalizations.
Map<String, Object?> subscriptionLocalizationCreate({
  required String subscriptionId,
  required String name,
  required String description,
  required String locale,
}) =>
    {
      'data': {
        'type': 'subscriptionLocalizations',
        'attributes': {
          'name': name,
          'description': description,
          'locale': locale,
        },
        'relationships': {'subscription': rel('subscriptions', subscriptionId)},
      }
    };

/// PATCH /v1/subscriptionLocalizations/{id} — drift reconcile: only sent when
/// the live name/description differ from the spec. Attribute casing verified
/// live (`name` / `description`, both writable).
Map<String, Object?> subscriptionLocalizationUpdate({
  required String id,
  required String name,
  required String description,
}) =>
    {
      'data': {
        'type': 'subscriptionLocalizations',
        'id': id,
        'attributes': {'name': name, 'description': description},
      }
    };

/// PATCH /v1/subscriptions/{id} — reconciles the internal reference name
/// (the localization PATCH above only covers the customer-facing display
/// name; the reference name is what the ASC lists show).
Map<String, Object?> subscriptionUpdate({
  required String id,
  required String name,
}) =>
    {
      'data': {
        'type': 'subscriptions',
        'id': id,
        'attributes': {'name': name},
      }
    };

/// POST /v2/inAppPurchases — InAppPurchaseV2CreateRequest.
Map<String, Object?> inAppPurchaseCreate({
  required String appId,
  required String productId,
  required String name,
  String inAppPurchaseType = 'NON_CONSUMABLE',
}) =>
    {
      'data': {
        'type': 'inAppPurchases',
        'attributes': {
          'productId': productId,
          'name': name,
          'inAppPurchaseType': inAppPurchaseType,
          'familySharable': false,
        },
        'relationships': {'app': rel('apps', appId)},
      }
    };

/// POST /v1/inAppPurchaseLocalizations (spec 4.x: relates to the v2 IAP
/// resource via `inAppPurchaseV2`).
Map<String, Object?> inAppPurchaseLocalizationCreate({
  required String inAppPurchaseId,
  required String name,
  required String description,
  required String locale,
}) =>
    {
      'data': {
        'type': 'inAppPurchaseLocalizations',
        'attributes': {
          'name': name,
          'description': description,
          'locale': locale,
        },
        'relationships': {
          'inAppPurchaseV2': rel('inAppPurchases', inAppPurchaseId)
        },
      }
    };

/// PATCH /v1/inAppPurchaseLocalizations/{id} — drift reconcile, same shape
/// as [subscriptionLocalizationUpdate].
Map<String, Object?> inAppPurchaseLocalizationUpdate({
  required String id,
  required String name,
  required String description,
}) =>
    {
      'data': {
        'type': 'inAppPurchaseLocalizations',
        'id': id,
        'attributes': {'name': name, 'description': description},
      }
    };

/// PATCH /v2/inAppPurchases/{id} — reconciles the internal reference name,
/// same rationale as [subscriptionUpdate].
Map<String, Object?> inAppPurchaseUpdate({
  required String id,
  required String name,
}) =>
    {
      'data': {
        'type': 'inAppPurchases',
        'id': id,
        'attributes': {'name': name},
      }
    };

/// POST /v1/subscriptionAvailabilities — SubscriptionAvailabilityCreateRequest
/// ("Modify the Territory Availability of a Subscription", API 3.0+). New
/// subscriptions are made available in every current and future territory —
/// the App Store Connect web default — which is also a hard prerequisite for
/// setting the starting price via POST /v1/subscriptionPrices (without it,
/// Apple rejects the price point relationship with a generic 409).
Map<String, Object?> subscriptionAvailabilityCreate({
  required String subscriptionId,
  required List<String> territoryIds,
  bool availableInNewTerritories = true,
}) =>
    {
      'data': {
        'type': 'subscriptionAvailabilities',
        'attributes': {
          'availableInNewTerritories': availableInNewTerritories
        },
        'relationships': {
          'subscription': rel('subscriptions', subscriptionId),
          'availableTerritories': {
            'data': [
              for (final id in territoryIds)
                {'type': 'territories', 'id': id}
            ]
          },
        },
      }
    };

/// POST /v1/subscriptionPrices — SubscriptionPriceCreateRequest ("Create a
/// Subscription Price Change"). Omitting startDate applies the price
/// immediately.
Map<String, Object?> subscriptionPriceCreate({
  required String subscriptionId,
  required String pricePointId,
  required String territoryId, // e.g. USA
}) =>
    {
      'data': {
        'type': 'subscriptionPrices',
        'relationships': {
          'subscription': rel('subscriptions', subscriptionId),
          'subscriptionPricePoint':
              rel('subscriptionPricePoints', pricePointId),
          'territory': rel('territories', territoryId),
        },
      }
    };

/// POST /v1/inAppPurchasePriceSchedules — InAppPurchasePriceScheduleCreateRequest
/// with one inline manual price in `included`. [manualPriceTempId] is the
/// JSON:API local id Apple uses in its examples (`${...}` style).
Map<String, Object?> inAppPurchasePriceScheduleCreate({
  required String inAppPurchaseId,
  required String pricePointId,
  required String baseTerritoryId, // e.g. USA
  String manualPriceTempId = '\${price1}',
}) =>
    {
      'data': {
        'type': 'inAppPurchasePriceSchedules',
        'relationships': {
          'inAppPurchase': rel('inAppPurchases', inAppPurchaseId),
          'baseTerritory': rel('territories', baseTerritoryId),
          'manualPrices': {
            'data': [
              {'type': 'inAppPurchasePrices', 'id': manualPriceTempId}
            ]
          },
        },
      },
      'included': [
        {
          'type': 'inAppPurchasePrices',
          'id': manualPriceTempId,
          'relationships': {
            'inAppPurchaseV2': rel('inAppPurchases', inAppPurchaseId),
            'inAppPurchasePricePoint':
                rel('inAppPurchasePricePoints', pricePointId),
          },
        }
      ],
    };
