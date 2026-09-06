import 'asc_payloads.dart';
import 'api_client.dart';
import 'money.dart';

/// One auto-renewable subscription to ensure inside the Pro group.
class SubscriptionSpec {
  const SubscriptionSpec({
    required this.productId,
    required this.name,
    required this.subscriptionPeriod,
    this.priceUsd,
  });

  final String productId;
  final String name;
  final String subscriptionPeriod; // ASC enum: ONE_MONTH, ONE_YEAR, ...
  final String? priceUsd;
}

/// Idempotently creates the Pro subscription group, the two subscriptions
/// (+ en-US localizations), the lifetime non-consumable IAP (+ localization)
/// and — when prices are passed — the USA base prices.
///
/// Field names / endpoints per Apple's OpenAPI spec v4.4.1 (see
/// asc_payloads.dart). Pricing uses the price-point + price-change /
/// price-schedule APIs introduced in ASC API 2.3+.
class AscProvisioner {
  AscProvisioner({
    required this.client,
    required this.appId,
    this.locale = 'en-US',
    this.territoryId = 'USA',
    void Function(String)? log,
  }) : _log = log ?? print;

  final ApiClient client;
  final String appId;
  final String locale;
  final String territoryId;
  final void Function(String) _log;

  static const groupReferenceName = 'Pro';
  static const lifetimeProductId = 'pro_lifetime';
  static const lifetimeName = 'Pro — Lifetime';

  /// Returns true when nothing failed. A missing price point is reported
  /// with the console deep-link and counts as a failure (exit non-zero) —
  /// the products exist but pricing is unfinished.
  Future<bool> run({
    required List<SubscriptionSpec> subscriptions,
    String? lifetimePriceUsd,
  }) async {
    var ok = true;

    // 1. Subscription group -------------------------------------------------
    final groupId = await _ensureSubscriptionGroup();
    await _ensureGroupLocalization(groupId);

    // 2. Subscriptions ------------------------------------------------------
    for (final spec in subscriptions) {
      final subId = await _ensureSubscription(groupId, spec);
      await _ensureSubscriptionLocalization(subId, spec.name);
      if (spec.priceUsd != null) {
        ok = await _ensureSubscriptionPrice(subId, spec) && ok;
      }
    }

    // 3. Lifetime non-consumable IAP ----------------------------------------
    final iapId = await _ensureInAppPurchase();
    await _ensureIapLocalization(iapId);
    if (lifetimePriceUsd != null) {
      ok = await _ensureIapPrice(iapId, lifetimePriceUsd) && ok;
    }

    return ok;
  }

  Future<String> _ensureSubscriptionGroup() async {
    final existing = await client.get('v1/apps/$appId/subscriptionGroups', {
      'filter[referenceName]': groupReferenceName,
      'limit': '200',
    });
    for (final group in existing.dataList) {
      final attrs = group['attributes'] as Map<String, Object?>?;
      if (attrs?['referenceName'] == groupReferenceName) {
        _log('subscription group "$groupReferenceName" already exists '
            '(id ${group['id']}) — skipping');
        return group['id'] as String;
      }
    }
    final created = await client.post(
        'v1/subscriptionGroups',
        subscriptionGroupCreate(
            appId: appId, referenceName: groupReferenceName));
    final id = created.dataObject?['id'] as String?;
    _log('created subscription group "$groupReferenceName" (id $id)');
    return id!;
  }

  Future<void> _ensureGroupLocalization(String groupId) async {
    final existing = await client.get(
        'v1/subscriptionGroups/$groupId/subscriptionGroupLocalizations',
        {'limit': '200'});
    if (existing.dataList.any((l) =>
        (l['attributes'] as Map<String, Object?>?)?['locale'] == locale)) {
      _log('group localization $locale already exists — skipping');
      return;
    }
    await client.post(
        'v1/subscriptionGroupLocalizations',
        subscriptionGroupLocalizationCreate(
            groupId: groupId, name: groupReferenceName, locale: locale));
    _log('created group localization $locale ("$groupReferenceName")');
  }

  Future<String> _ensureSubscription(String groupId, SubscriptionSpec spec) async {
    final existing = await client.get(
        'v1/subscriptionGroups/$groupId/subscriptions', {
      'filter[productId]': spec.productId,
      'limit': '200',
    });
    for (final sub in existing.dataList) {
      if ((sub['attributes'] as Map<String, Object?>?)?['productId'] ==
          spec.productId) {
        _log('subscription ${spec.productId} already exists '
            '(id ${sub['id']}) — skipping');
        return sub['id'] as String;
      }
    }
    final created = await client.post(
        'v1/subscriptions',
        subscriptionCreate(
          groupId: groupId,
          productId: spec.productId,
          name: spec.name,
          subscriptionPeriod: spec.subscriptionPeriod,
        ));
    final id = created.dataObject?['id'] as String?;
    _log('created subscription ${spec.productId} '
        '(${spec.subscriptionPeriod}, id $id)');
    return id!;
  }

  Future<void> _ensureSubscriptionLocalization(
      String subscriptionId, String name) async {
    final existing = await client.get(
        'v1/subscriptions/$subscriptionId/subscriptionLocalizations',
        {'limit': '200'});
    if (existing.dataList.any((l) =>
        (l['attributes'] as Map<String, Object?>?)?['locale'] == locale)) {
      _log('  localization $locale already exists — skipping');
      return;
    }
    await client.post(
        'v1/subscriptionLocalizations',
        subscriptionLocalizationCreate(
            subscriptionId: subscriptionId, name: name, locale: locale));
    _log('  created localization $locale ("$name")');
  }

  Future<bool> _ensureSubscriptionPrice(
      String subscriptionId, SubscriptionSpec spec) async {
    final existing = await client.get('v1/subscriptions/$subscriptionId/prices', {
      'filter[territory]': territoryId,
      'limit': '50',
    });
    if (existing.dataList.isNotEmpty) {
      _log('  price already set for $territoryId — skipping');
      return true;
    }
    final pointId =
        await _findSubscriptionPricePoint(subscriptionId, spec.priceUsd!);
    if (pointId == null) {
      if (client.isDryRun) {
        _log('  would look up the $territoryId price point for USD '
            '${spec.priceUsd} and POST it — price points are not simulated '
            'in dry-run');
        return true;
      }
      _log('  ERROR: no $territoryId price point for USD ${spec.priceUsd} on '
          '${spec.productId}. Set the price manually: '
          'https://appstoreconnect.apple.com/apps/$appId/distribution/'
          'subscriptions (subscription id $subscriptionId)');
      return false;
    }
    try {
      await client.post(
          'v1/subscriptionPrices',
          subscriptionPriceCreate(
            subscriptionId: subscriptionId,
            pricePointId: pointId,
            territoryId: territoryId,
          ));
    } on ApiException catch (e) {
      // A 409 here with "error occurred while processing the pricing
      // information" on a subscription's FIRST price almost always means an
      // account-level block (Paid Apps agreement / tax / banking not
      // active) — the payload and price point are not the problem.
      _log('  ERROR: setting the $territoryId price failed: $e\n'
          '  If this is the subscription\'s first price, check App Store '
          'Connect → Business → Agreements, Tax, and Banking — the Paid Apps '
          'agreement (incl. bank account + tax forms) must be Active before '
          'pricing works.');
      return false;
    }
    _log('  set $territoryId price USD ${spec.priceUsd} '
        '(price point $pointId) — other territories follow the base '
        'territory price automatically');
    return true;
  }

  Future<String?> _findSubscriptionPricePoint(
      String subscriptionId, String priceUsd) =>
      _findPricePoint('v1/subscriptions/$subscriptionId/pricePoints', priceUsd);

  /// ASC returns ~800 price points per territory, paged at 200 — scan all
  /// pages via meta.paging.nextCursor. `include=territory` matches every
  /// known-working implementation and keeps the ids usable for writes.
  Future<String?> _findPricePoint(String path, String priceUsd) async {
    final wanted = normalizePrice(priceUsd);
    String? cursor;
    do {
      final points = await client.get(path, {
        'filter[territory]': territoryId,
        'limit': '200',
        'include': 'territory',
        if (cursor != null) 'cursor': cursor,
      });
      for (final point in points.dataList) {
        final attrs = point['attributes'] as Map<String, Object?>?;
        if (attrs?['customerPrice'] == wanted) return point['id'] as String;
      }
      final meta = points.json['meta'];
      final paging = meta is Map ? meta['paging'] : null;
      cursor = paging is Map ? paging['nextCursor'] as String? : null;
    } while (cursor != null);
    return null;
  }

  Future<String> _ensureInAppPurchase() async {
    final existing = await client.get('v1/apps/$appId/inAppPurchasesV2', {
      'filter[productId]': lifetimeProductId,
      'limit': '200',
    });
    for (final iap in existing.dataList) {
      if ((iap['attributes'] as Map<String, Object?>?)?['productId'] ==
          lifetimeProductId) {
        _log('in-app purchase $lifetimeProductId already exists '
            '(id ${iap['id']}) — skipping');
        return iap['id'] as String;
      }
    }
    final created = await client.post(
        'v2/inAppPurchases',
        inAppPurchaseCreate(
            appId: appId, productId: lifetimeProductId, name: lifetimeName));
    final id = created.dataObject?['id'] as String?;
    _log('created non-consumable IAP $lifetimeProductId (id $id)');
    return id!;
  }

  Future<void> _ensureIapLocalization(String iapId) async {
    final existing = await client.get(
        'v2/inAppPurchases/$iapId/inAppPurchaseLocalizations',
        {'limit': '200'});
    if (existing.dataList.any((l) =>
        (l['attributes'] as Map<String, Object?>?)?['locale'] == locale)) {
      _log('  localization $locale already exists — skipping');
      return;
    }
    await client.post(
        'v1/inAppPurchaseLocalizations',
        inAppPurchaseLocalizationCreate(
            inAppPurchaseId: iapId, name: lifetimeName, locale: locale));
    _log('  created localization $locale ("$lifetimeName")');
  }

  Future<bool> _ensureIapPrice(String iapId, String priceUsd) async {
    final schedule =
        await client.getOrNull('v2/inAppPurchases/$iapId/iapPriceSchedule');
    if (schedule != null && schedule.dataObject != null) {
      _log('  price schedule already exists — skipping');
      return true;
    }
    final pointId = await _findPricePoint(
        'v2/inAppPurchases/$iapId/pricePoints', priceUsd);
    if (pointId == null) {
      if (client.isDryRun) {
        _log('  would look up the $territoryId price point for USD '
            '$priceUsd and POST the price schedule — price points are not '
            'simulated in dry-run');
        return true;
      }
      _log('  ERROR: no $territoryId price point for USD $priceUsd on '
          '$lifetimeProductId. Set the price manually: '
          'https://appstoreconnect.apple.com/apps/$appId/distribution/'
          'in-app-purchases (IAP id $iapId)');
      return false;
    }
    try {
      await client.post(
          'v1/inAppPurchasePriceSchedules',
          inAppPurchasePriceScheduleCreate(
            inAppPurchaseId: iapId,
            pricePointId: pointId,
            baseTerritoryId: territoryId,
          ));
    } on ApiException catch (e) {
      // See _ensureSubscriptionPrice: a 409 on the first price is usually an
      // account-level block (Paid Apps agreement / tax / banking).
      _log('  ERROR: setting the $territoryId price failed: $e\n'
          '  If this is the IAP\'s first price, check App Store Connect → '
          'Business → Agreements, Tax, and Banking — the Paid Apps agreement '
          '(incl. bank account + tax forms) must be Active before pricing '
          'works.');
      return false;
    }
    _log('  set $territoryId price USD $priceUsd (price point $pointId) — '
        'other territories follow the base territory price automatically');
    return true;
  }
}
