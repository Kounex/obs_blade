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

/// Wanted per-region price table: Play region code (alpha-2) → Play `Money`
/// map. Built by the provisioner from `pricing:convertRegionPrices` with
/// nominal-parity overrides.
typedef RegionPrices = Map<String, Map<String, Object?>>;

/// A region price table plus the regions version it was computed from —
/// writes must pass that same `regionsVersion` or Play rejects regions
/// whose currency changed between versions (e.g. BG → EUR).
typedef RegionPriceTable = ({RegionPrices prices, String regionsVersion});

/// One region's config entry, in base-plan (`regionalConfigs`) or purchase
/// option (`regionalPricingAndAvailabilityConfigs`) shape.
Map<String, Object?> _regionalConfig(
  String region,
  Map<String, Object?> price, {
  required bool subscription,
}) => subscription
    ? {'regionCode': region, 'newSubscriberAvailability': true, 'price': price}
    : {'regionCode': region, 'availability': 'AVAILABLE', 'price': price};

/// Full per-region config list for [prices] (sorted by region code so
/// payloads and tests are deterministic).
List<Map<String, Object?>> regionalConfigList(
  RegionPrices prices, {
  required bool subscription,
}) => [
  for (final region in (prices.keys.toList()..sort()).cast<String>())
    _regionalConfig(region, prices[region]!, subscription: subscription),
];

/// True when [configs] (a base plan's `regionalConfigs` or a purchase
/// option's `regionalPricingAndAvailabilityConfigs`) already carries every
/// wanted region with the wanted price (currency + units + nanos). Extra
/// regions on the live side are ignored.
bool regionPricesMatch(List<Object?>? configs, RegionPrices wanted) {
  final existing = {
    for (final c in (configs ?? const []).whereType<Map<String, Object?>>())
      c['regionCode'] as String: c['price'] as Map<String, Object?>?,
  };
  for (final entry in wanted.entries) {
    final price = existing[entry.key];
    final w = entry.value;
    if (price == null ||
        price['currencyCode'] != w['currencyCode'] ||
        price['units'] != w['units'] ||
        (price['nanos'] ?? 0) != (w['nanos'] ?? 0)) {
      return false;
    }
  }
  return true;
}

Map<String, Object?> _basePlan(BasePlanSpec spec, RegionPrices prices) => {
  'basePlanId': spec.basePlanId,
  'autoRenewingBasePlanType': {
    'billingPeriodDuration': spec.billingPeriodDuration,
  },
  'regionalConfigs': regionalConfigList(prices, subscription: true),
};

Map<String, Object?> _listing(String title, String languageCode) => {
  'languageCode': languageCode,
  'title': title,
  'description': 'OBS Blade Pro',
};

/// Play requires a listing in the app's default language (en-GB for OBS
/// Blade); en-US is included for the US storefront.
List<Map<String, Object?>> _listings(String title) => [
  _listing(title, 'en-GB'),
  _listing(title, 'en-US'),
];

/// Copy of [existingPlan] with the regional configs replaced by the wanted
/// [prices]; other plan fields stay untouched.
Map<String, Object?> basePlanWithRegionPrices(
  Map<String, Object?> existingPlan,
  RegionPrices prices,
) => {
  ...existingPlan,
  'regionalConfigs': regionalConfigList(prices, subscription: true),
};

/// Body for POST .../applications/{packageName}/subscriptions.
Map<String, Object?> subscriptionCreate({
  required String packageName,
  required String productId,
  required String title,
  required List<BasePlanSpec> basePlans,

  /// Wanted per-region prices per base plan id.
  required Map<String, RegionPrices> pricesByPlan,
}) => {
  'packageName': packageName,
  'productId': productId,
  'listings': _listings(title),
  'basePlans': basePlans
      .map((spec) => _basePlan(spec, pricesByPlan[spec.basePlanId]!))
      .toList(),
};

/// Body for PATCH .../applications/{packageName}/subscriptions/{productId}
/// (updateMask: basePlans) — used when the subscription product already
/// exists but base plans are missing or region prices drifted. Existing base
/// plans are carried over (with corrected configs where drifted); listings
/// are deliberately not sent (nor masked) so re-runs don't clobber
/// console-customized listing text.
Map<String, Object?> subscriptionPatch({
  required List<Map<String, Object?>> existingBasePlans,
  required List<BasePlanSpec> missing,

  /// Wanted per-region prices per base plan id.
  required Map<String, RegionPrices> pricesByPlan,
}) => {
  'basePlans': [
    ...existingBasePlans,
    ...missing.map((spec) => _basePlan(spec, pricesByPlan[spec.basePlanId]!)),
  ],
};

/// Body for POST .../basePlans/{basePlanId}:activate.
Map<String, Object?> activateBasePlan({
  required String packageName,
  required String productId,
  required String basePlanId,
}) => {
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

  /// Wanted per-region prices for the purchase option.
  required RegionPrices prices,
  String regionsVersion = '2022/02',
}) => {
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
            'regionalPricingAndAvailabilityConfigs': regionalConfigList(
              prices,
              subscription: false,
            ),
          },
        ],
      },
    },
  ],
};

/// Body for POST .../oneTimeProducts/{productId}/purchaseOptions:batchUpdateStates.
Map<String, Object?> activatePurchaseOption({
  required String packageName,
  required String productId,
  required String purchaseOptionId,
}) => {
  'requests': [
    {
      'activatePurchaseOptionRequest': {
        'packageName': packageName,
        'productId': productId,
        'purchaseOptionId': purchaseOptionId,
      },
    },
  ],
};
