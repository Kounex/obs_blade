import 'api_client.dart';
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

  String get _apps => 'androidpublisher/v3/applications/$packageName';

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
          regionCode: regionCode,
        ),
        {
          'productId': subscriptionProductId,
          'regionsVersion.version': regionsVersion,
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
      // Existing plans whose US price drifted from the wanted price.
      final drifted = basePlans.where((spec) {
        final plan = existingBasePlans
            .where((b) => b['basePlanId'] == spec.basePlanId)
            .firstOrNull;
        return plan != null &&
            !priceConfigsMatch(
              plan['regionalConfigs'] as List?,
              regionCode,
              spec.priceUsd,
            );
      }).toList();
      if (missing.isEmpty && drifted.isEmpty) {
        _log('all base plans already exist with matching prices — skipping');
      } else {
        final corrected = [
          for (final b in existingBasePlans)
            drifted.any((s) => s.basePlanId == b['basePlanId'])
                ? basePlanWithPrice(
                    b,
                    basePlans.firstWhere(
                      (s) => s.basePlanId == b['basePlanId'],
                    ),
                    regionCode,
                  )
                : b,
        ];
        await client.patch(
          path,
          subscriptionPatch(
            existingBasePlans: corrected,
            missing: missing,
            regionCode: regionCode,
          ),
          {
            // basePlans only — `listings` stays untouched so re-runs don't
            // clobber console-customized listing text. (The full listing is
            // set on initial create instead.)
            'updateMask': 'basePlans',
            'regionsVersion.version': regionsVersion,
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
            'updated prices for base plans: ${drifted.map((b) => '${b.basePlanId} → USD ${b.priceUsd}').join(', ')}',
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
    var product = await client.getOrNull(path);
    if (product != null) {
      final existingOption =
          ((product.json['purchaseOptions'] as List?) ?? const [])
              .whereType<Map<String, Object?>>()
              .where((o) => o['purchaseOptionId'] == purchaseOptionId)
              .firstOrNull;
      final priceMatches =
          existingOption != null &&
          priceConfigsMatch(
            existingOption['regionalPricingAndAvailabilityConfigs'] as List?,
            regionCode,
            priceUsd,
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
            priceUsd: priceUsd,
            regionCode: regionCode,
          ),
        );
        _log(
          'updated one-time product $lifetimeProductId'
          '${priceMatches ? '' : ' to USD $priceUsd'}'
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
          priceUsd: priceUsd,
          regionCode: regionCode,
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
