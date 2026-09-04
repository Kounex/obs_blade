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
      _log('created subscription $subscriptionProductId with base plans '
          '${basePlans.map((b) => b.basePlanId).join(', ')} (DRAFT)');
      existingBasePlans = const [];
    } else {
      _log('subscription $subscriptionProductId already exists — skipping '
          'create');
      existingBasePlans =
          ((existing.json['basePlans'] as List?) ?? const [])
              .whereType<Map<String, Object?>>()
              .toList();
      final existingIds = existingBasePlans
          .map((b) => b['basePlanId'] as String?)
          .toSet();
      final missing = basePlans
          .where((spec) => !existingIds.contains(spec.basePlanId))
          .toList();
      if (missing.isEmpty) {
        _log('all base plans already exist — skipping');
      } else {
        await client.patch(
          path,
          subscriptionPatch(
            existingBasePlans: existingBasePlans,
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
        _log('added missing base plans: '
            '${missing.map((b) => b.basePlanId).join(', ')}');
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
        _log('ERROR activating base plan ${spec.basePlanId}: $e — activate '
            'it in Play Console → Monetize → Products → Subscriptions');
        ok = false;
      }
    }
    return ok;
  }

  Future<bool> _ensureOneTimeProduct(String priceUsd) async {
    final path = '$_apps/oneTimeProducts/$lifetimeProductId';
    var product = await client.getOrNull(path);
    if (product != null) {
      _log('one-time product $lifetimeProductId already exists — skipping '
          'create');
    } else {
      await client.post(
        '$_apps/oneTimeProducts:batchUpdate',
        oneTimeProductUpsert(
          packageName: packageName,
          productId: lifetimeProductId,
          purchaseOptionId: purchaseOptionId,
          title: 'Pro — Lifetime',
          priceUsd: priceUsd,
          regionCode: regionCode,
        ),
      );
      _log('created one-time product $lifetimeProductId '
          '(purchase option $purchaseOptionId, USD $priceUsd)');
      product = await client.getOrNull(path);
    }

    if (!activate) {
      _log('activation disabled (--no-activate) — purchase option stays '
          'DRAFT');
      return true;
    }
    final options =
        ((product?.json['purchaseOptions'] as List?) ?? const [])
            .whereType<Map<String, Object?>>();
    final option = options.where(
        (o) => o['purchaseOptionId'] == purchaseOptionId).firstOrNull;
    final state = option?['state'] as String? ?? 'DRAFT';
    if (state == 'ACTIVE') {
      _log('purchase option $purchaseOptionId already ACTIVE — skipping');
      return true;
    }
    if (state == 'INACTIVE_PUBLISHED') {
      _log('purchase option $purchaseOptionId is INACTIVE_PUBLISHED '
          '(was live, then deactivated) — skipping; reactivate manually '
          'if this was deliberate');
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
      _log('ERROR activating purchase option $purchaseOptionId: $e — '
          'activate it in Play Console → Monetize → Products → '
          'One-time products');
      return false;
    }
  }
}
