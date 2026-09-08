import 'api_client.dart';
import 'money.dart';
import 'play_payloads.dart';

/// Idempotently creates the Play side of Pro: one subscription product
/// holding the yearly + monthly base plans (with US pricing) and the
/// lifetime one-time product. Base plans are created in DRAFT state (Play
/// sets `state` itself) and then activated via the dedicated endpoints.
class PlayProvisioner {
  PlayProvisioner({
    required this.client,
    required this.packageName,
    this.subscriptionProductId = 'pro',
    this.lifetimeProductId = 'pro_lifetime',
    this.purchaseOptionId = 'pro-lifetime',
    this.regionCode = 'US',
    this.activate = true,
    void Function(String)? log,
  }) : _log = log ?? print;

  final ApiClient client;
  final String packageName;
  final String subscriptionProductId;
  final String lifetimeProductId;
  final String purchaseOptionId;
  final String regionCode;

  /// Whether to activate base plans / the purchase option after creation.
  final bool activate;

  final void Function(String) _log;

  static const regionsVersion = '2022/02';
  static const subscriptionTitle = 'Pro';
  static const lifetimeTitle = 'Pro - Lifetime';

  /// Currencies that get the USD nominal verbatim (4.99 → 4.99 EUR / GBP /
  /// USD) instead of Google's FX-converted price — the "western parity" the
  /// App Store side also uses.
  static const nominalParityCurrencies = {'EUR', 'GBP', 'USD'};

  String get _apps => 'androidpublisher/v3/applications/$packageName';

  /// Memoized per-nominal region price tables — see [_regionPrices].
  final _regionPriceCache = <String, RegionPriceTable>{};

  /// The wanted price for EVERY Play region for a USD nominal: Play's own
  /// `pricing:convertRegionPrices` table (already conventionally rounded
  /// per market, e.g. ¥840 / ₹550), with nominal parity for
  /// [nominalParityCurrencies] (€4.99 / £4.99 / $4.99). Pinning the table
  /// explicitly stops Play's auto-conversion from drifting with FX rates.
  /// The table's `regionVersion` must accompany every write using it —
  /// Play rejects regions whose currency changed since the older version
  /// (e.g. BG is EUR in 2025/03 but BGN in 2022/02).
  Future<RegionPriceTable> _regionPrices(String priceUsd) async {
    final cached = _regionPriceCache[priceUsd];
    if (cached != null) return cached;
    final nominal = moneyFromDecimal(priceUsd);
    RegionPriceTable fallback() =>
        (prices: {regionCode: nominal}, regionsVersion: regionsVersion);
    if (client.isDryRun) {
      _log(
        '  would pin prices in every Play region for USD $priceUsd '
        '(convertRegionPrices table + EUR/GBP/USD nominal parity) — not '
        'simulated in dry-run; using $regionCode only',
      );
      return _regionPriceCache[priceUsd] = fallback();
    }
    final res = await client.post('$_apps/pricing:convertRegionPrices', {
      'price': nominal,
    });
    final converted =
        (res.json['convertedRegionPrices'] as Map<String, Object?>?) ?? {};
    if (converted.isEmpty) {
      _log(
        '  WARNING: convertRegionPrices returned no regions for USD '
        '$priceUsd — falling back to $regionCode only',
      );
      return _regionPriceCache[priceUsd] = fallback();
    }
    final tableVersion =
        ((res.json['regionVersion'] as Map<String, Object?>?)?['version']
            as String?) ??
        regionsVersion;
    final prices = <String, Map<String, Object?>>{};
    for (final entry in converted.entries) {
      final price =
          (entry.value as Map<String, Object?>?)?['price']
              as Map<String, Object?>?;
      final currency = price?['currencyCode'] as String?;
      if (price == null || currency == null) continue;
      prices[entry.key] = nominalParityCurrencies.contains(currency)
          ? moneyFromDecimal(priceUsd, currencyCode: currency)
          : {
              'currencyCode': currency,
              'units': '${price['units'] ?? '0'}',
              'nanos': price['nanos'] ?? 0,
            };
    }
    _log(
      '  region price table for USD $priceUsd: ${prices.length} regions '
      '(regions version $tableVersion; EUR/GBP/USD at nominal parity, rest '
      'Google-converted)',
    );
    return _regionPriceCache[priceUsd] = (
      prices: prices,
      regionsVersion: tableVersion,
    );
  }

  Future<bool> run({
    required List<BasePlanSpec> basePlans,
    required String lifetimePriceUsd,
  }) async {
    var ok = true;
    ok = await _ensureSubscription(basePlans) && ok;
    ok = await _ensureOneTimeProduct(lifetimePriceUsd) && ok;
    return ok;
  }

  Future<bool> _ensureSubscription(List<BasePlanSpec> basePlans) async {
    final path = '$_apps/subscriptions/$subscriptionProductId';
    final tables = <String, RegionPriceTable>{
      for (final spec in basePlans)
        spec.basePlanId: await _regionPrices(spec.priceUsd),
    };
    final pricesByPlan = <String, RegionPrices>{
      for (final e in tables.entries) e.key: e.value.prices,
    };
    // All tables share the same version (same convertRegionPrices surface).
    final tableRegionsVersion = tables.values.first.regionsVersion;
    final existing = await client.getOrNull(path);
    List<Map<String, Object?>> existingBasePlans;
    if (existing == null) {
      await client.post(
        '$_apps/subscriptions',
        subscriptionCreate(
          packageName: packageName,
          productId: subscriptionProductId,
          title: subscriptionTitle,
          basePlans: basePlans,
          pricesByPlan: pricesByPlan,
        ),
        {
          'productId': subscriptionProductId,
          'regionsVersion.version': tableRegionsVersion,
        },
      );
      _log(
        'created subscription $subscriptionProductId with base plans '
        '${basePlans.map((b) => b.basePlanId).join(', ')} (DRAFT)',
      );
      existingBasePlans = const [];
    } else {
      _log(
        'subscription $subscriptionProductId already exists — skipping '
        'create',
      );
      existingBasePlans = ((existing.json['basePlans'] as List?) ?? const [])
          .whereType<Map<String, Object?>>()
          .toList();
      final existingIds = existingBasePlans
          .map((b) => b['basePlanId'] as String?)
          .toSet();
      final missing = basePlans
          .where((spec) => !existingIds.contains(spec.basePlanId))
          .toList();
      // Existing plans whose per-region prices drifted from the wanted
      // table (or only carry the legacy single-region config).
      final drifted = basePlans.where((spec) {
        final plan = existingBasePlans
            .where((b) => b['basePlanId'] == spec.basePlanId)
            .firstOrNull;
        return plan != null &&
            !regionPricesMatch(
              plan['regionalConfigs'] as List?,
              pricesByPlan[spec.basePlanId]!,
            );
      }).toList();
      if (missing.isEmpty && drifted.isEmpty) {
        _log('all base plans already exist with matching prices — skipping');
      } else {
        final corrected = [
          for (final b in existingBasePlans)
            drifted.any((s) => s.basePlanId == b['basePlanId'])
                ? basePlanWithRegionPrices(
                    b,
                    pricesByPlan[b['basePlanId'] as String]!,
                  )
                : b,
        ];
        await client.patch(
          path,
          subscriptionPatch(
            existingBasePlans: corrected,
            missing: missing,
            pricesByPlan: pricesByPlan,
          ),
          {
            // basePlans only — `listings` stays untouched so re-runs don't
            // clobber console-customized listing text. (The full listing is
            // set on initial create instead.)
            'updateMask': 'basePlans',
            'regionsVersion.version': tableRegionsVersion,
          },
        );
        if (missing.isNotEmpty) {
          _log(
            'added missing base plans: '
            '${missing.map((b) => b.basePlanId).join(', ')}',
          );
        }
        if (drifted.isNotEmpty) {
          _log(
            'updated prices for base plans: ${drifted.map((b) => '${b.basePlanId} → USD ${b.priceUsd} '
                '(${pricesByPlan[b.basePlanId]!.length} regions)').join(', ')}',
          );
        }
      }
    }

    if (!activate) {
      _log('activation disabled (--no-activate) — base plans stay DRAFT');
      return true;
    }
    // Re-read to learn each base plan's state.
    final current = await client.getOrNull(path);
    final states = <String, String>{
      for (final b
          in ((current?.json['basePlans'] as List?) ?? const [])
              .whereType<Map<String, Object?>>())
        (b['basePlanId'] as String): (b['state'] as String? ?? 'DRAFT'),
    };
    var ok = true;
    for (final spec in basePlans) {
      final state = states[spec.basePlanId] ?? 'DRAFT';
      if (state == 'ACTIVE') {
        _log('base plan ${spec.basePlanId} already ACTIVE — skipping');
        continue;
      }
      try {
        await client.post(
          '$_apps/subscriptions/$subscriptionProductId/basePlans/'
          '${spec.basePlanId}:activate',
          activateBasePlan(
            packageName: packageName,
            productId: subscriptionProductId,
            basePlanId: spec.basePlanId,
          ),
        );
        _log('activated base plan ${spec.basePlanId}');
      } on ApiException catch (e) {
        _log(
          'ERROR activating base plan ${spec.basePlanId}: $e — activate '
          'it in Play Console → Monetize → Products → Subscriptions',
        );
        ok = false;
      }
    }
    return ok;
  }

  Future<bool> _ensureOneTimeProduct(String priceUsd) async {
    final path = '$_apps/oneTimeProducts/$lifetimeProductId';
    final table = await _regionPrices(priceUsd);
    final prices = table.prices;
    var product = await client.getOrNull(path);
    if (product != null) {
      final existingOption =
          ((product.json['purchaseOptions'] as List?) ?? const [])
              .whereType<Map<String, Object?>>()
              .where((o) => o['purchaseOptionId'] == purchaseOptionId)
              .firstOrNull;
      final priceMatches =
          existingOption != null &&
          regionPricesMatch(
            existingOption['regionalPricingAndAvailabilityConfigs'] as List?,
            prices,
          );
      // Listings are only written by the upsert below, so a drifted title
      // (e.g. an old em-dash) must also trigger it.
      final titleDrifted =
          ((product.json['listings'] as List? ?? const [])
                      .whereType<Map<String, Object?>>()
                      .where((l) => l['languageCode'] == 'en-US')
                      .firstOrNull?['title']
                  as String? ??
              '') !=
          lifetimeTitle;
      if (priceMatches && !titleDrifted) {
        _log(
          'one-time product $lifetimeProductId already exists with '
          'matching price + listing — skipping',
        );
      } else {
        // Same call as the create: batchUpdate with allowMissing upserts
        // listings + purchase options, so it also serves as a price /
        // listing update.
        await client.post(
          '$_apps/oneTimeProducts:batchUpdate',
          oneTimeProductUpsert(
            packageName: packageName,
            productId: lifetimeProductId,
            purchaseOptionId: purchaseOptionId,
            title: lifetimeTitle,
            prices: prices,
            regionsVersion: table.regionsVersion,
          ),
        );
        _log(
          'updated one-time product $lifetimeProductId'
          '${priceMatches ? '' : ' to USD $priceUsd (${prices.length} regions)'}'
          '${titleDrifted ? ' (listing title → "$lifetimeTitle")' : ''}',
        );
        product = await client.getOrNull(path);
      }
    } else {
      await client.post(
        '$_apps/oneTimeProducts:batchUpdate',
        oneTimeProductUpsert(
          packageName: packageName,
          productId: lifetimeProductId,
          purchaseOptionId: purchaseOptionId,
          title: lifetimeTitle,
          prices: prices,
          regionsVersion: table.regionsVersion,
        ),
      );
      _log(
        'created one-time product $lifetimeProductId '
        '(purchase option $purchaseOptionId, USD $priceUsd)',
      );
      product = await client.getOrNull(path);
    }

    if (!activate) {
      _log(
        'activation disabled (--no-activate) — purchase option stays '
        'DRAFT',
      );
      return true;
    }
    final options = ((product?.json['purchaseOptions'] as List?) ?? const [])
        .whereType<Map<String, Object?>>();
    final option = options
        .where((o) => o['purchaseOptionId'] == purchaseOptionId)
        .firstOrNull;
    final state = option?['state'] as String? ?? 'DRAFT';
    if (state == 'ACTIVE') {
      _log('purchase option $purchaseOptionId already ACTIVE — skipping');
      return true;
    }
    if (state == 'INACTIVE_PUBLISHED') {
      _log(
        'purchase option $purchaseOptionId is INACTIVE_PUBLISHED '
        '(was live, then deactivated) — skipping; reactivate manually '
        'if this was deliberate',
      );
      return true;
    }
    try {
      await client.post(
        '$path/purchaseOptions:batchUpdateStates',
        activatePurchaseOption(
          packageName: packageName,
          productId: lifetimeProductId,
          purchaseOptionId: purchaseOptionId,
        ),
      );
      _log('activated purchase option $purchaseOptionId');
      return true;
    } on ApiException catch (e) {
      _log(
        'ERROR activating purchase option $purchaseOptionId: $e — '
        'activate it in Play Console → Monetize → Products → '
        'One-time products',
      );
      return false;
    }
  }
}
