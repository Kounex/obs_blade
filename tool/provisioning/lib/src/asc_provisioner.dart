import 'dart:convert';

import 'asc_payloads.dart';
import 'api_client.dart';
import 'money.dart';

/// One auto-renewable subscription to ensure inside the Pro group.
class SubscriptionSpec {
  const SubscriptionSpec({
    required this.productId,
    required this.name,
    required this.description,
    required this.subscriptionPeriod,
    this.priceUsd,
  });

  final String productId;
  final String name;
  final String description;
  final String subscriptionPeriod; // ASC enum: ONE_MONTH, ONE_YEAR, ...
  final String? priceUsd;
}

/// Idempotently creates the Pro subscription group, the two subscriptions
/// (+ en-US localizations), the lifetime non-consumable IAP (+ localization)
/// and — when prices are passed — a current price in EVERY available
/// territory with nominal parity (the territory price point whose
/// `customerPrice` equals the USD nominal string). The IAP keeps a USA base
/// price only (its price schedule auto-equalizes all other territories).
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
  static const lifetimeName = 'Pro - Lifetime';
  static const lifetimeDescription = 'Lifetime Pro Access';

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
      await _ensureSubscriptionLocalization(subId, spec);
      final territories = await _subscriptionTerritoryIds(subId);
      if (spec.priceUsd != null) {
        ok = await _ensureTerritoryPrices(subId, spec, territories) && ok;
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
        final id = sub['id'] as String;
        final referenceName =
            (sub['attributes'] as Map<String, Object?>?)?['name'];
        if (referenceName != spec.name) {
          await client.patch(
              'v1/subscriptions/$id',
              subscriptionUpdate(id: id, name: spec.name));
          _log('  reference name drifted ("$referenceName") — patched to '
              '"${spec.name}"');
        }
        return id;
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
      String subscriptionId, SubscriptionSpec spec) async {
    final existing = await client.get(
        'v1/subscriptions/$subscriptionId/subscriptionLocalizations',
        {'limit': '200'});
    final loc = existing.dataList
        .where((l) =>
            (l['attributes'] as Map<String, Object?>?)?['locale'] == locale)
        .firstOrNull;
    if (loc == null) {
      await client.post(
          'v1/subscriptionLocalizations',
          subscriptionLocalizationCreate(
              subscriptionId: subscriptionId,
              name: spec.name,
              description: spec.description,
              locale: locale));
      _log('  created localization $locale ("${spec.name}")');
      return;
    }
    final attrs = loc['attributes'] as Map<String, Object?>?;
    if (attrs?['name'] == spec.name &&
        attrs?['description'] == spec.description) {
      _log('  localization $locale already matches — skipping');
      return;
    }
    await client.patch(
        'v1/subscriptionLocalizations/${loc['id']}',
        subscriptionLocalizationUpdate(
            id: loc['id'] as String,
            name: spec.name,
            description: spec.description));
    _log('  updated localization $locale → "${spec.name}" / '
        '"${spec.description}" (drifted from spec)');
  }

  /// Returns the territory ids the subscription is available in, creating the
  /// availability (all current + future territories) first when missing —
  /// territory availability is a hard prerequisite for setting any price
  /// (Apple answers a generic 409 on the price POST otherwise).
  ///
  /// When availability already exists the territories are read from the
  /// related collection endpoint
  /// `GET /v1/subscriptionAvailabilities/{id}/availableTerritories` — the
  /// availability resource shares the subscription's id, and its plain
  /// response only carries relationship links (verified live: 175
  /// territories, paged via the standard meta.paging.nextCursor).
  Future<List<String>> _subscriptionTerritoryIds(String subscriptionId) async {
    final existing = await client
        .getOrNull('v1/subscriptionAvailabilities/$subscriptionId');
    if (existing?.dataObject != null) {
      final ids = <String>[];
      String? cursor;
      do {
        final page = await client.get(
            'v1/subscriptionAvailabilities/$subscriptionId/'
            'availableTerritories', {
          'limit': '200',
          if (cursor != null) 'cursor': cursor,
        });
        ids.addAll(page.dataList.map((t) => t['id'] as String));
        final meta = page.json['meta'];
        final paging = meta is Map ? meta['paging'] : null;
        cursor = paging is Map ? paging['nextCursor'] as String? : null;
      } while (cursor != null);
      _log('  available in ${ids.length} territories');
      return ids;
    }
    final territories = await client.get('v1/territories', {'limit': '200'});
    final ids = territories.dataList.map((t) => t['id'] as String).toList();
    await client.post(
        'v1/subscriptionAvailabilities',
        subscriptionAvailabilityCreate(
            subscriptionId: subscriptionId, territoryIds: ids));
    _log('  made available in ${ids.isEmpty ? 'all' : '${ids.length}'} '
        'territories (+ future territories)');
    return ids;
  }

  /// Sets a current price in EVERY available territory with nominal parity:
  /// the price point whose `customerPrice` equals the USD nominal string
  /// ('4.99' → 4.99 EUR in DEU, 4.99 GBP in GBR, …). Subscriptions get no
  /// auto-derived territory prices (unlike IAP price schedules), so each
  /// territory needs its own POST /v1/subscriptionPrices.
  ///
  /// Idempotent: a territory whose current price (the record without a
  /// startDate) already matches the nominal is skipped. Territories without
  /// an exact nominal price point are collected, warned about and reported
  /// in a summary — they don't fail the run.
  Future<bool> _ensureTerritoryPrices(String subscriptionId,
      SubscriptionSpec spec, List<String> territories) async {
    if (territories.isEmpty) {
      if (client.isDryRun) {
        _log('  would set the nominal-parity price USD ${spec.priceUsd} in '
            'every available territory — territories and price points are '
            'not simulated in dry-run');
        return true;
      }
      _log('  ERROR: no territories found for ${spec.productId} — cannot '
          'set prices');
      return false;
    }
    final skipped = <String>[];
    var ok = true;
    for (final territory in territories) {
      final result =
          await _ensureTerritoryPrice(subscriptionId, spec, territory);
      switch (result) {
        case _TerritoryPriceResult.ok:
          break;
        case _TerritoryPriceResult.noPricePoint:
          skipped.add(territory);
        case _TerritoryPriceResult.failed:
          ok = false;
      }
    }
    if (skipped.isNotEmpty) {
      _log('  WARNING: ${spec.productId}: no ${normalizePrice(spec.priceUsd!)} '
          'price point in ${skipped.length} territories — skipped: '
          '${skipped.join(', ')}');
    }
    return ok;
  }

  Future<_TerritoryPriceResult> _ensureTerritoryPrice(
      String subscriptionId, SubscriptionSpec spec, String territory) {
    return _retry429(() =>
        _ensureTerritoryPriceOnce(subscriptionId, spec, territory));
  }

  Future<_TerritoryPriceResult> _ensureTerritoryPriceOnce(
      String subscriptionId, SubscriptionSpec spec, String territory) async {
    final wanted = normalizePrice(spec.priceUsd!);
    final existing =
        await client.get('v1/subscriptions/$subscriptionId/prices', {
      'filter[territory]': territory,
      'limit': '50',
      'include': 'subscriptionPricePoint',
    });
    if (existing.dataList.isNotEmpty) {
      // The current price is the one without a startDate.
      final current = existing.dataList.firstWhere(
          (p) =>
              (p['attributes'] as Map<String, Object?>?)?['startDate'] == null,
          orElse: () => existing.dataList.first);
      final currentPointId = (((current['relationships']
                  as Map<String, Object?>?)?['subscriptionPricePoint']
              as Map<String, Object?>?)?['data'] as Map<String, Object?>?)?['id'];
      final currentPrice = _includedPricePointPrice(existing, currentPointId);
      if (currentPrice == wanted) {
        _log('  $territory: price already $wanted — skipping');
        return _TerritoryPriceResult.ok;
      }
      _log('  $territory: price differs (have $currentPrice, want $wanted) — '
          'creating a price change');
    }
    final pointId = await _findPricePoint(
        'v1/subscriptions/$subscriptionId/pricePoints', spec.priceUsd!,
        territory: territory);
    if (pointId == null) {
      if (client.isDryRun) {
        _log('  $territory: would look up the $wanted price point and POST '
            'it — price points are not simulated in dry-run');
        return _TerritoryPriceResult.ok;
      }
      return _TerritoryPriceResult.noPricePoint;
    }
    try {
      await client.post(
          'v1/subscriptionPrices',
          subscriptionPriceCreate(
            subscriptionId: subscriptionId,
            pricePointId: pointId,
            territoryId: territory,
          ));
    } on ApiException catch (e) {
      // A 409 here with "error occurred while processing the pricing
      // information" on a subscription's FIRST price almost always means an
      // account-level block (Paid Apps agreement / tax / banking not
      // active) — the payload and price point are not the problem.
      _log('  ERROR: setting the $territory price failed: $e\n'
          '  If this is the subscription\'s first price, check App Store '
          'Connect → Business → Agreements, Tax, and Banking — the Paid Apps '
          'agreement (incl. bank account + tax forms) must be Active before '
          'pricing works.');
      return _TerritoryPriceResult.failed;
    }
    _log('  $territory: set price $wanted (price point $pointId)');
    return _TerritoryPriceResult.ok;
  }

  /// Retries once after a short wait on HTTP 429 (ASC rate limit).
  Future<T> _retry429<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on ApiException catch (e) {
      if (e.statusCode != 429) rethrow;
      _log('  rate-limited (429) — waiting 5s and retrying once');
      await Future<void>.delayed(const Duration(seconds: 5));
      return call();
    }
  }

  /// customerPrice of the price point with [pointId] in the response's
  /// `included` section (from a prices fetch with
  /// `include=subscriptionPricePoint`).
  String? _includedPricePointPrice(ApiResponse response, Object? pointId) {
    final included = response.json['included'];
    if (included is! List) return null;
    for (final item in included.whereType<Map<String, Object?>>()) {
      if (item['id'] == pointId) {
        return (item['attributes']
            as Map<String, Object?>?)?['customerPrice'] as String?;
      }
    }
    return null;
  }

  /// Apple's price point / manual price ids are base64url-encoded JSON with
  /// an embedded tier (`{"s":…,"t":…,"p":"10477"}`). inAppPurchasePrices has
  /// no read endpoint, so comparing the `p` field is the only way to check
  /// an IAP's current price against a wanted price point. Returns null when
  /// the id doesn't decode (callers then treat the price as different).
  static String? _priceTierOf(String? id) {
    if (id == null) return null;
    try {
      final padded = id + '=' * ((4 - id.length % 4) % 4);
      final decoded = jsonDecode(utf8.decode(base64Url.decode(padded)));
      return decoded is Map ? decoded['p'] as String? : null;
    } catch (_) {
      return null;
    }
  }

  /// ASC returns ~800 price points per territory, paged at 200 — scan pages
  /// via meta.paging.nextCursor. `include=territory` matches every
  /// known-working implementation and keeps the ids usable for writes.
  ///
  /// Points come back sorted ascending by customerPrice (verified live), so
  /// the scan stops early once a point exceeds the target price.
  Future<String?> _findPricePoint(String path, String priceUsd,
      {String? territory}) async {
    final wanted = normalizePrice(priceUsd);
    final target = double.parse(wanted);
    String? cursor;
    do {
      final points = await client.get(path, {
        'filter[territory]': territory ?? territoryId,
        'limit': '200',
        'include': 'territory',
        if (cursor != null) 'cursor': cursor,
      });
      for (final point in points.dataList) {
        final attrs = point['attributes'] as Map<String, Object?>?;
        final customerPrice = attrs?['customerPrice'] as String?;
        if (customerPrice == wanted) return point['id'] as String;
        if (customerPrice != null &&
            double.tryParse(customerPrice) != null &&
            double.parse(customerPrice) > target) {
          return null; // sorted ascending — the target can't come later
        }
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
        final id = iap['id'] as String;
        final referenceName =
            (iap['attributes'] as Map<String, Object?>?)?['name'];
        if (referenceName != lifetimeName) {
          await client.patch('v2/inAppPurchases/$id',
              inAppPurchaseUpdate(id: id, name: lifetimeName));
          _log('  reference name drifted ("$referenceName") — patched to '
              '"$lifetimeName"');
        }
        return id;
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
    final loc = existing.dataList
        .where((l) =>
            (l['attributes'] as Map<String, Object?>?)?['locale'] == locale)
        .firstOrNull;
    if (loc == null) {
      await client.post(
          'v1/inAppPurchaseLocalizations',
          inAppPurchaseLocalizationCreate(
              inAppPurchaseId: iapId,
              name: lifetimeName,
              description: lifetimeDescription,
              locale: locale));
      _log('  created localization $locale ("$lifetimeName")');
      return;
    }
    final attrs = loc['attributes'] as Map<String, Object?>?;
    if (attrs?['name'] == lifetimeName &&
        attrs?['description'] == lifetimeDescription) {
      _log('  localization $locale already matches — skipping');
      return;
    }
    await client.patch(
        'v1/inAppPurchaseLocalizations/${loc['id']}',
        inAppPurchaseLocalizationUpdate(
            id: loc['id'] as String,
            name: lifetimeName,
            description: lifetimeDescription));
    _log('  updated localization $locale → "$lifetimeName" / '
        '"$lifetimeDescription" (drifted from spec)');
  }

  Future<bool> _ensureIapPrice(String iapId, String priceUsd) async {
    // include=manualPrices: the only way to read the current base price —
    // inAppPurchasePrices has no direct read/write operations (403).
    final schedule = await client
        .getOrNull('v2/inAppPurchases/$iapId/iapPriceSchedule', {
      'include': 'manualPrices',
    });
    final pointId = await _findPricePoint(
        'v2/inAppPurchases/$iapId/pricePoints', priceUsd);
    if (schedule != null && schedule.dataObject != null) {
      final manualPrices = (((schedule.dataObject!['relationships']
              as Map<String, Object?>?)?['manualPrices']
          as Map<String, Object?>?)?['data'] as List?)?.whereType<Map<String, Object?>>();
      final currentId = manualPrices == null || manualPrices.isEmpty
          ? null
          : manualPrices.first['id'] as String?;
      // The point tier is only comparable via the id's embedded `p` field;
      // undecodable ids are treated as different (safe: the re-POST
      // replaces the schedule).
      final currentTier = _priceTierOf(currentId);
      final wantedTier = _priceTierOf(pointId);
      if (currentTier != null && currentTier == wantedTier) {
        _log('  price schedule already at USD $priceUsd — skipping');
        return true;
      }
      _log('  price schedule exists with a different price — replacing it '
          '(re-POSTing the schedule is create-or-replace)');
    }
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

/// Outcome of one territory's price ensure — missing price points are
/// collected and reported (not fatal), POST failures fail the run.
enum _TerritoryPriceResult { ok, noPricePoint, failed }
