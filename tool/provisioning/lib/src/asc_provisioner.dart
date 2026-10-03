import 'dart:convert';

import 'asc_payloads.dart';
import 'api_client.dart';
import 'money.dart';
import 'pricing_targets.dart';

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
/// territory from the reviewed [PricingTargets] table (anchor currencies at
/// the USD nominal, everything else at Google's converted table, snapped to
/// the nearest App Store price point). The IAP keeps a USA base price only
/// (its price schedule auto-equalizes all other territories and Apple keeps
/// that schedule FX-current — verified 2026-10; unlike subscription prices,
/// which Apple never auto-updates, hence the checked-in table).
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

  /// Territory id → currency, fetched once per run (v1/territories).
  Map<String, String>? _territoryCurrencies;

  /// ASC territories whose currency prices per region — the [PricingTargets]
  /// per-region rows are keyed by Play region code, so map the ISO-3
  /// territory to its ISO-2 equivalent (CHF is the only conflicted
  /// currency: CH and LI price differently).
  static const _territoryRegionOverride = {'CHE': 'CH', 'LIE': 'LI'};

  /// How far the snapped price point may deviate from the target before the
  /// log calls it out (Apple's point granularity is fine enough that
  /// anything larger is worth a human look).
  static const _snapWarnThreshold = 0.02;

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
        _log(
          'subscription group "$groupReferenceName" already exists '
          '(id ${group['id']}) — skipping',
        );
        return group['id'] as String;
      }
    }
    final created = await client.post(
      'v1/subscriptionGroups',
      subscriptionGroupCreate(appId: appId, referenceName: groupReferenceName),
    );
    final id = created.dataObject?['id'] as String?;
    _log('created subscription group "$groupReferenceName" (id $id)');
    return id!;
  }

  Future<void> _ensureGroupLocalization(String groupId) async {
    final existing = await client.get(
      'v1/subscriptionGroups/$groupId/subscriptionGroupLocalizations',
      {'limit': '200'},
    );
    if (existing.dataList.any(
      (l) => (l['attributes'] as Map<String, Object?>?)?['locale'] == locale,
    )) {
      _log('group localization $locale already exists — skipping');
      return;
    }
    await client.post(
      'v1/subscriptionGroupLocalizations',
      subscriptionGroupLocalizationCreate(
        groupId: groupId,
        name: groupReferenceName,
        locale: locale,
      ),
    );
    _log('created group localization $locale ("$groupReferenceName")');
  }

  Future<String> _ensureSubscription(
    String groupId,
    SubscriptionSpec spec,
  ) async {
    final existing = await client.get(
      'v1/subscriptionGroups/$groupId/subscriptions',
      {'filter[productId]': spec.productId, 'limit': '200'},
    );
    for (final sub in existing.dataList) {
      if ((sub['attributes'] as Map<String, Object?>?)?['productId'] ==
          spec.productId) {
        _log(
          'subscription ${spec.productId} already exists '
          '(id ${sub['id']}) — skipping',
        );
        final id = sub['id'] as String;
        final referenceName =
            (sub['attributes'] as Map<String, Object?>?)?['name'];
        if (referenceName != spec.name) {
          await client.patch(
            'v1/subscriptions/$id',
            subscriptionUpdate(id: id, name: spec.name),
          );
          _log(
            '  reference name drifted ("$referenceName") — patched to '
            '"${spec.name}"',
          );
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
      ),
    );
    final id = created.dataObject?['id'] as String?;
    _log(
      'created subscription ${spec.productId} '
      '(${spec.subscriptionPeriod}, id $id)',
    );
    return id!;
  }

  Future<void> _ensureSubscriptionLocalization(
    String subscriptionId,
    SubscriptionSpec spec,
  ) async {
    final existing = await client.get(
      'v1/subscriptions/$subscriptionId/subscriptionLocalizations',
      {'limit': '200'},
    );
    final loc = existing.dataList
        .where(
          (l) =>
              (l['attributes'] as Map<String, Object?>?)?['locale'] == locale,
        )
        .firstOrNull;
    if (loc == null) {
      await client.post(
        'v1/subscriptionLocalizations',
        subscriptionLocalizationCreate(
          subscriptionId: subscriptionId,
          name: spec.name,
          description: spec.description,
          locale: locale,
        ),
      );
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
        description: spec.description,
      ),
    );
    _log(
      '  updated localization $locale → "${spec.name}" / '
      '"${spec.description}" (drifted from spec)',
    );
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
    final existing = await client.getOrNull(
      'v1/subscriptionAvailabilities/$subscriptionId',
    );
    if (existing?.dataObject != null) {
      final ids = <String>[];
      String? cursor;
      do {
        final page = await client.get(
          'v1/subscriptionAvailabilities/$subscriptionId/'
          'availableTerritories',
          {'limit': '200', if (cursor != null) 'cursor': cursor},
        );
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
        subscriptionId: subscriptionId,
        territoryIds: ids,
      ),
    );
    _log(
      '  made available in ${ids.isEmpty ? 'all' : '${ids.length}'} '
      'territories (+ future territories)',
    );
    return ids;
  }

  /// Sets a current price in EVERY available territory from the reviewed
  /// [PricingTargets] table: anchor currencies (USD/EUR/GBP) at the USD
  /// nominal, every other currency at Google's converted price, snapped to
  /// the nearest App Store price point in that territory. Subscriptions get
  /// no auto-derived territory prices (unlike IAP price schedules) and Apple
  /// never auto-updates them, so each territory needs its own POST
  /// /v1/subscriptionPrices — and this table is what keeps them correct.
  ///
  /// Idempotent: a territory whose current price point (or already-scheduled
  /// price change) is the one we'd pick is skipped (point-id comparison —
  /// the snapped point's price string need not equal the target).
  /// Territories whose currency has no target (shouldn't happen — the table
  /// covers every ASC currency) are skipped with a warning and don't fail
  /// the run. Approved subscriptions reject immediate prices, so those
  /// changes are scheduled 2 days out instead (existing subscribers keep
  /// their price).
  Future<bool> _ensureTerritoryPrices(
    String subscriptionId,
    SubscriptionSpec spec,
    List<String> territories,
  ) async {
    if (territories.isEmpty) {
      if (client.isDryRun) {
        _log(
          '  would set the reviewed-table price for USD ${spec.priceUsd} in '
          'every available territory — territories and price points are '
          'not simulated in dry-run',
        );
        return true;
      }
      _log(
        '  ERROR: no territories found for ${spec.productId} — cannot '
        'set prices',
      );
      return false;
    }
    final skipped = <String>[];
    final snapped = <String, String>{};
    var ok = true;
    for (final territory in territories) {
      final (:result, :snapNote) = await _ensureTerritoryPrice(
        subscriptionId,
        spec,
        territory,
      );
      if (snapNote != null) snapped[territory] = snapNote;
      switch (result) {
        case _TerritoryPriceResult.ok:
          break;
        case _TerritoryPriceResult.noPricePoint:
          skipped.add(territory);
        case _TerritoryPriceResult.failed:
          ok = false;
      }
    }
    if (snapped.isNotEmpty) {
      _log(
        '  ${spec.productId}: snapped to the nearest price point '
        '(>${(_snapWarnThreshold * 100).round()}% off target): '
        '${snapped.entries.map((e) => '${e.key}→${e.value}').join(', ')}',
      );
    }
    if (skipped.isNotEmpty) {
      _log(
        '  WARNING: ${spec.productId}: no target or usable price point in '
        '${skipped.length} territories — skipped: ${skipped.join(', ')}',
      );
    }
    return ok;
  }

  Future<({_TerritoryPriceResult result, String? snapNote})>
  _ensureTerritoryPrice(
    String subscriptionId,
    SubscriptionSpec spec,
    String territory,
  ) {
    return _retry429(
      () => _ensureTerritoryPriceOnce(subscriptionId, spec, territory),
    );
  }

  /// Sets the current price for one territory from the [PricingTargets]
  /// table (per-territory override, else per-currency). The target point is
  /// the exact-price point when one exists, else the numerically nearest
  /// one (deviations beyond [_snapWarnThreshold] are reported back as
  /// [snapNote]). Idempotent via point-id comparison.
  Future<({_TerritoryPriceResult result, String? snapNote})>
  _ensureTerritoryPriceOnce(
    String subscriptionId,
    SubscriptionSpec spec,
    String territory,
  ) async {
    final currency = await _currencyOf(territory);
    final wanted = currency == null
        ? null
        : PricingTargets.target(
            currency,
            spec.priceUsd!,
            region: _territoryRegionOverride[territory],
          );
    if (wanted == null) {
      _log(
        '  $territory: no pricing target for currency ${currency ?? '?'} — '
        'extend PricingTargets',
      );
      return (result: _TerritoryPriceResult.noPricePoint, snapNote: null);
    }
    final target = double.parse(wanted);
    final existing = await client
        .get('v1/subscriptions/$subscriptionId/prices', {
          'filter[territory]': territory,
          'limit': '50',
          'include': 'subscriptionPricePoint',
        });
    // The current price is the one without a startDate (else the latest
    // past-dated one — an implemented change keeps its startDate); a
    // future-dated one is a scheduled change (at most one per territory —
    // scheduling a second overwrites the first).
    final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    String? currentPointId;
    String? currentDate;
    String? scheduledPointId;
    String? scheduledDate;
    for (final p in existing.dataList) {
      final startDate =
          (p['attributes'] as Map<String, Object?>?)?['startDate'] as String?;
      final pointId =
          (((p['relationships']
                          as Map<String, Object?>?)?['subscriptionPricePoint']
                      as Map<String, Object?>?)?['data']
                  as Map<String, Object?>?)?['id']
              as String?;
      if (startDate == null) {
        // The initial/current price — always wins over past-dated records.
        if (currentDate != null || currentPointId == null) {
          currentPointId = pointId;
          currentDate = null;
        }
      } else if (startDate.compareTo(today) > 0) {
        if (scheduledDate == null || startDate.compareTo(scheduledDate) > 0) {
          scheduledPointId = pointId;
          scheduledDate = startDate;
        }
      } else if (currentDate != null
          ? startDate.compareTo(currentDate) > 0
          : currentPointId == null) {
        // An implemented change keeps its startDate — latest past wins.
        currentPointId = pointId;
        currentDate = startDate;
      }
    }
    final currentPrice = _includedPricePointPrice(existing, currentPointId);
    final path = 'v1/subscriptions/$subscriptionId/pricePoints';
    final point = await _findNearestPricePoint(
      path,
      wanted,
      territory: territory,
    );
    if (point == null) {
      if (client.isDryRun) {
        _log(
          '  $territory: would look up the $wanted price point (or the '
          'nearest one) and POST it — price points are not simulated in '
          'dry-run',
        );
        return (result: _TerritoryPriceResult.ok, snapNote: null);
      }
      return (result: _TerritoryPriceResult.noPricePoint, snapNote: null);
    }
    final pointValue = double.tryParse(point.price);
    final snapNote =
        pointValue != null &&
            (pointValue / target - 1).abs() > _snapWarnThreshold
        ? '${point.price} (target $wanted)'
        : null;
    if (currentPointId == point.id) {
      _log('  $territory: price already ${point.price} — skipping');
      return (result: _TerritoryPriceResult.ok, snapNote: snapNote);
    }
    if (scheduledPointId == point.id) {
      _log(
        '  $territory: price change to ${point.price} already scheduled '
        '(starts $scheduledDate) — skipping',
      );
      return (result: _TerritoryPriceResult.ok, snapNote: snapNote);
    }
    final post = await _postTerritoryPrice(subscriptionId, point.id, territory);
    if (!post.ok) {
      return (result: _TerritoryPriceResult.failed, snapNote: null);
    }
    _log(
      post.scheduledFor == null
          ? '  $territory: set price ${point.price}'
                '${currentPrice == null ? '' : ' (was $currentPrice)'}'
                '${point.price == wanted ? '' : ' — snapped from target $wanted'} '
                '(price point ${point.id})'
          : '  $territory: scheduled price ${point.price} starting '
                '${post.scheduledFor}'
                '${currentPrice == null ? '' : ' (was $currentPrice)'}'
                '${point.price == wanted ? '' : ' — snapped from target $wanted'} '
                '(price point ${point.id})',
    );
    return (result: _TerritoryPriceResult.ok, snapNote: snapNote);
  }

  /// POSTs the current-price record for one territory. Approved
  /// subscriptions reject an immediate price (409 STATE_ERROR: "Initial
  /// price cannot be created again after subscription is approved") — those
  /// get a scheduled price change instead (start date 2 days out, the
  /// soonest Apple schedules; existing subscribers keep their price — we
  /// only re-price for new buyers). Returns false (after logging) on API
  /// errors instead of throwing so one bad territory doesn't abort the run.
  Future<({bool ok, String? scheduledFor})> _postTerritoryPrice(
    String subscriptionId,
    String pointId,
    String territory,
  ) async {
    try {
      await client.post(
        'v1/subscriptionPrices',
        subscriptionPriceCreate(
          subscriptionId: subscriptionId,
          pricePointId: pointId,
          territoryId: territory,
        ),
      );
      return (ok: true, scheduledFor: null);
    } on ApiException catch (e) {
      if (e.statusCode != 409 || !'$e'.contains('STATE_ERROR')) {
        // A 409 here with "error occurred while processing the pricing
        // information" on a subscription's FIRST price almost always means an
        // account-level block (Paid Apps agreement / tax / banking not
        // active) — the payload and price point are not the problem.
        _log(
          '  ERROR: setting the $territory price failed: $e\n'
          '  If this is the subscription\'s first price, check App Store '
          'Connect → Business → Agreements, Tax, and Banking — the Paid Apps '
          'agreement (incl. bank account + tax forms) must be Active before '
          'pricing works.',
        );
        return (ok: false, scheduledFor: null);
      }
      // Approved subscription — immediate prices are rejected; schedule.
      final startDate = DateTime.now()
          .toUtc()
          .add(const Duration(days: 2))
          .toIso8601String()
          .substring(0, 10);
      try {
        await client.post(
          'v1/subscriptionPrices',
          subscriptionPriceCreate(
            subscriptionId: subscriptionId,
            pricePointId: pointId,
            territoryId: territory,
            startDate: startDate,
          ),
        );
        return (ok: true, scheduledFor: startDate);
      } on ApiException catch (e2) {
        _log('  ERROR: scheduling the $territory price change failed: $e2');
        return (ok: false, scheduledFor: null);
      }
    }
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
        return (item['attributes'] as Map<String, Object?>?)?['customerPrice']
            as String?;
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
  Future<String?> _findPricePoint(
    String path,
    String priceUsd, {
    String? territory,
  }) async {
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

  /// Territory id → currency, cached per run.
  Future<String?> _currencyOf(String territory) async {
    final map = _territoryCurrencies ??= {};
    if (map.isEmpty) {
      final territories = await client.get('v1/territories', {'limit': '200'});
      for (final t in territories.dataList) {
        final currency =
            (t['attributes'] as Map<String, Object?>?)?['currency'] as String?;
        final id = t['id'] as String?;
        if (currency != null && id != null) map[id] = currency;
      }
    }
    return map[territory];
  }

  /// The price point for [wanted] in [territory]: the exact-price point when
  /// one exists, else the numerically nearest one (ties go to the lower
  /// point). Points come back sorted ascending by customerPrice (verified
  /// live), so the nearest point is decided as soon as a point exceeds the
  /// target — the scan stops there.
  Future<({String id, String price})?> _findNearestPricePoint(
    String path,
    String wanted, {
    String? territory,
  }) async {
    final target = double.parse(normalizePrice(wanted));
    ({String id, String price})? lastBelow;
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
        final raw = attrs?['customerPrice'] as String?;
        final value = raw == null ? null : double.tryParse(raw);
        if (value == null) continue;
        final id = point['id'] as String;
        if (value == target) return (id: id, price: raw!);
        if (value > target) {
          // Sorted ascending — the nearest point is this one or the last
          // one below (tie → the lower point).
          if (lastBelow == null) return (id: id, price: raw!);
          final belowDiff = target - double.parse(lastBelow.price);
          return belowDiff <= value - target
              ? lastBelow
              : (id: id, price: raw!);
        }
        lastBelow = (id: id, price: raw!);
      }
      final meta = points.json['meta'];
      final paging = meta is Map ? meta['paging'] : null;
      cursor = paging is Map ? paging['nextCursor'] as String? : null;
    } while (cursor != null);
    return lastBelow; // every point is below the target — take the highest
  }

  Future<String> _ensureInAppPurchase() async {
    final existing = await client.get('v1/apps/$appId/inAppPurchasesV2', {
      'filter[productId]': lifetimeProductId,
      'limit': '200',
    });
    for (final iap in existing.dataList) {
      if ((iap['attributes'] as Map<String, Object?>?)?['productId'] ==
          lifetimeProductId) {
        _log(
          'in-app purchase $lifetimeProductId already exists '
          '(id ${iap['id']}) — skipping',
        );
        final id = iap['id'] as String;
        final referenceName =
            (iap['attributes'] as Map<String, Object?>?)?['name'];
        if (referenceName != lifetimeName) {
          await client.patch(
            'v2/inAppPurchases/$id',
            inAppPurchaseUpdate(id: id, name: lifetimeName),
          );
          _log(
            '  reference name drifted ("$referenceName") — patched to '
            '"$lifetimeName"',
          );
        }
        return id;
      }
    }
    final created = await client.post(
      'v2/inAppPurchases',
      inAppPurchaseCreate(
        appId: appId,
        productId: lifetimeProductId,
        name: lifetimeName,
      ),
    );
    final id = created.dataObject?['id'] as String?;
    _log('created non-consumable IAP $lifetimeProductId (id $id)');
    return id!;
  }

  Future<void> _ensureIapLocalization(String iapId) async {
    final existing = await client.get(
      'v2/inAppPurchases/$iapId/inAppPurchaseLocalizations',
      {'limit': '200'},
    );
    final loc = existing.dataList
        .where(
          (l) =>
              (l['attributes'] as Map<String, Object?>?)?['locale'] == locale,
        )
        .firstOrNull;
    if (loc == null) {
      await client.post(
        'v1/inAppPurchaseLocalizations',
        inAppPurchaseLocalizationCreate(
          inAppPurchaseId: iapId,
          name: lifetimeName,
          description: lifetimeDescription,
          locale: locale,
        ),
      );
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
        description: lifetimeDescription,
      ),
    );
    _log(
      '  updated localization $locale → "$lifetimeName" / '
      '"$lifetimeDescription" (drifted from spec)',
    );
  }

  Future<bool> _ensureIapPrice(String iapId, String priceUsd) async {
    // include=manualPrices: the only way to read the current base price —
    // inAppPurchasePrices has no direct read/write operations (403).
    final schedule = await client.getOrNull(
      'v2/inAppPurchases/$iapId/iapPriceSchedule',
      {'include': 'manualPrices'},
    );
    final pointId = await _findPricePoint(
      'v2/inAppPurchases/$iapId/pricePoints',
      priceUsd,
    );
    if (schedule != null && schedule.dataObject != null) {
      final manualPrices =
          (((schedule.dataObject!['relationships']
                          as Map<String, Object?>?)?['manualPrices']
                      as Map<String, Object?>?)?['data']
                  as List?)
              ?.whereType<Map<String, Object?>>();
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
      _log(
        '  price schedule exists with a different price — replacing it '
        '(re-POSTing the schedule is create-or-replace)',
      );
    }
    if (pointId == null) {
      if (client.isDryRun) {
        _log(
          '  would look up the $territoryId price point for USD '
          '$priceUsd and POST the price schedule — price points are not '
          'simulated in dry-run',
        );
        return true;
      }
      _log(
        '  ERROR: no $territoryId price point for USD $priceUsd on '
        '$lifetimeProductId. Set the price manually: '
        'https://appstoreconnect.apple.com/apps/$appId/distribution/'
        'in-app-purchases (IAP id $iapId)',
      );
      return false;
    }
    try {
      await client.post(
        'v1/inAppPurchasePriceSchedules',
        inAppPurchasePriceScheduleCreate(
          inAppPurchaseId: iapId,
          pricePointId: pointId,
          baseTerritoryId: territoryId,
        ),
      );
    } on ApiException catch (e) {
      // See _ensureSubscriptionPrice: a 409 on the first price is usually an
      // account-level block (Paid Apps agreement / tax / banking).
      _log(
        '  ERROR: setting the $territoryId price failed: $e\n'
        '  If this is the IAP\'s first price, check App Store Connect → '
        'Business → Agreements, Tax, and Banking — the Paid Apps agreement '
        '(incl. bank account + tax forms) must be Active before pricing '
        'works.',
      );
      return false;
    }
    _log(
      '  set $territoryId price USD $priceUsd (price point $pointId) — '
      'other territories follow the base territory price automatically',
    );
    return true;
  }
}

/// Outcome of one territory's price ensure — missing price points are
/// collected and reported (not fatal), POST failures fail the run.
enum _TerritoryPriceResult { ok, noPricePoint, failed }
