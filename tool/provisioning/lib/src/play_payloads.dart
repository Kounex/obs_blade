import 'money.dart';

/// Pure request-body builders for the Play Developer API (androidpublisher
/// v3) calls the play-products command makes. Field names verified against
/// the live discovery doc
/// (https://androidpublisher.googleapis.com/$discovery/rest?version=v3).

/// One base plan to ensure on the Pro subscription product.
class BasePlanSpec {
  const BasePlanSpec({
    required this.basePlanId, // RFC-1034: lowercase letters/numbers/hyphens
    required this.billingPeriodDuration, // ISO-8601 duration: P1M / P1Y
    required this.priceUsd,
  });

  final String basePlanId;
  final String billingPeriodDuration;
  final String priceUsd;
}

Map<String, Object?> _basePlan(BasePlanSpec spec, String regionCode) => {
      'basePlanId': spec.basePlanId,
      'autoRenewingBasePlanType': {
        'billingPeriodDuration': spec.billingPeriodDuration,
      },
      'regionalConfigs': [
        {
          'regionCode': regionCode,
          'newSubscriberAvailability': true,
          'price': moneyFromDecimal(spec.priceUsd),
        }
      ],
    };

Map<String, Object?> _listing(String title, String languageCode) => {
      'languageCode': languageCode,
      'title': title,
      'description': 'OBS Blade Pro',
    };

/// Play requires a listing in the app's default language (en-GB for OBS
/// Blade); en-US is included for the US storefront.
List<Map<String, Object?>> _listings(String title) =>
    [_listing(title, 'en-GB'), _listing(title, 'en-US')];

/// Body for POST .../applications/{packageName}/subscriptions.
Map<String, Object?> subscriptionCreate({
  required String packageName,
  required String productId,
  required String title,
  required List<BasePlanSpec> basePlans,
  String regionCode = 'US',
}) =>
    {
      'packageName': packageName,
      'productId': productId,
      'listings': _listings(title),
      'basePlans':
          basePlans.map((spec) => _basePlan(spec, regionCode)).toList(),
    };

/// Body for PATCH .../applications/{packageName}/subscriptions/{productId}
/// (updateMask: basePlans) — used when the subscription product already
/// exists but base plans are missing. Existing base plans are carried over
/// verbatim; listings are deliberately not sent (nor masked) so re-runs
/// don't clobber console-customized listing text.
Map<String, Object?> subscriptionPatch({
  required List<Map<String, Object?>> existingBasePlans,
  required List<BasePlanSpec> missing,
  String regionCode = 'US',
}) =>
    {
      'basePlans': [
        ...existingBasePlans,
        ...missing.map((spec) => _basePlan(spec, regionCode)),
      ],
    };

/// Body for POST .../basePlans/{basePlanId}:activate.
Map<String, Object?> activateBasePlan({
  required String packageName,
  required String productId,
  required String basePlanId,
}) =>
    {
      'packageName': packageName,
      'productId': productId,
      'basePlanId': basePlanId,
    };

/// Body for POST .../applications/{packageName}/oneTimeProducts:batchUpdate
/// with allowMissing → creates the one-time product if absent.
Map<String, Object?> oneTimeProductUpsert({
  required String packageName,
  required String productId,
  required String purchaseOptionId,
  required String title,
  required String priceUsd,
  String regionCode = 'US',
  String regionsVersion = '2022/02',
}) =>
    {
      'requests': [
        {
          'regionsVersion': {'version': regionsVersion},
          'updateMask': 'listings,purchaseOptions',
          'allowMissing': true,
          'oneTimeProduct': {
            'packageName': packageName,
            'productId': productId,
            'listings': _listings(title),
            'purchaseOptions': [
              {
                'purchaseOptionId': purchaseOptionId,
                'buyOption': {'legacyCompatible': true},
                'regionalPricingAndAvailabilityConfigs': [
                  {
                    'regionCode': regionCode,
                    'availability': 'AVAILABLE',
                    'price': moneyFromDecimal(priceUsd),
                  }
                ],
              }
            ],
          },
        }
      ],
    };

/// Body for POST .../oneTimeProducts/{productId}/purchaseOptions:batchUpdateStates.
Map<String, Object?> activatePurchaseOption({
  required String packageName,
  required String productId,
  required String purchaseOptionId,
}) =>
    {
      'requests': [
        {
          'activatePurchaseOptionRequest': {
            'packageName': packageName,
            'productId': productId,
            'purchaseOptionId': purchaseOptionId,
          }
        }
      ],
    };
