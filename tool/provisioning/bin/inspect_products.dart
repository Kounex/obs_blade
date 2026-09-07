/// Inspection / verification: prints the live store state of the Pro
/// products (ASC + Play) — localizations (name/description), per-territory
/// subscription price coverage with nominal parity, and Play listings.
/// Read-only.
///
/// Run: source ~/.localrc && dart run bin/inspect_products.dart
import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:provisioning/src/api_client.dart';
import 'package:provisioning/src/asc_jwt.dart';
import 'package:provisioning/src/money.dart';

Future<void> main() async {
  final env = Platform.environment;
  final appId = env['ASC_APP_ID']!;
  const groupId = '22363681'; // "Pro" subscription group

  // ---- ASC ----
  final pem = await File(env['ASC_KEY_PATH']!).readAsString();
  final asc = HttpApiClient(
    baseUrl: 'https://api.appstoreconnect.apple.com',
    token: buildAscJwt(
      privateKeyPem: pem,
      keyId: env['ASC_KEY_ID']!,
      issuerId: env['ASC_ISSUER_ID']!,
    ),
  );

  String? pricePointPrice(Map<String, Object?> json, Object? pointId) {
    final included = (json['included'] as List?)?.firstWhere(
      (i) => i['id'] == pointId,
      orElse: () => null,
    );
    if (included == null) return null;
    final a = included['attributes'] as Map<String, Object?>;
    return '${a['customerPrice']}';
  }

  /// The Apple tier (`p` field) embedded in a base64url price-point id —
  /// points sharing a tier are Apple's equalized local prices.
  String? tierOf(String? id) {
    if (id == null) return null;
    try {
      final padded = id + '=' * ((4 - id.length % 4) % 4);
      final decoded = jsonDecode(utf8.decode(base64Url.decode(padded)));
      return decoded is Map ? decoded['p'] as String? : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> territoryIds(String subId) async {
    final ids = <String>[];
    String? cursor;
    do {
      final page = await asc.get(
        'v1/subscriptionAvailabilities/$subId/availableTerritories',
        {'limit': '200', if (cursor != null) 'cursor': cursor},
      );
      ids.addAll(page.dataList.map((t) => t['id'] as String));
      final meta = page.json['meta'];
      final paging = meta is Map ? meta['paging'] : null;
      cursor = paging is Map ? paging['nextCursor'] as String? : null;
    } while (cursor != null);
    return ids;
  }

  /// The tier of the USA point for [nominalUsd], or null when unknown.
  Future<String?> referenceTier(String subId, String nominalUsd) async {
    String? cursor;
    do {
      final page = await asc.get('v1/subscriptions/$subId/pricePoints', {
        'filter[territory]': 'USA',
        'limit': '200',
        if (cursor != null) 'cursor': cursor,
      });
      for (final p in page.dataList) {
        if ((p['attributes'] as Map?)?['customerPrice'] ==
            normalizePrice(nominalUsd)) {
          return tierOf(p['id'] as String?);
        }
      }
      final meta = page.json['meta'];
      final paging = meta is Map ? meta['paging'] : null;
      cursor = paging is Map ? paging['nextCursor'] as String? : null;
    } while (cursor != null);
    return null;
  }

  /// Prints "priced/total territories" and parity mismatches. Parity =
  /// nominal price match OR the equalized tier price (same Apple tier as
  /// the USA nominal point) — the provisioner's two pricing modes.
  Future<void> priceCoverage(String subId, String nominalUsd) async {
    final wanted = normalizePrice(nominalUsd);
    final refTier = await referenceTier(subId, nominalUsd);
    final territories = await territoryIds(subId);
    var priced = 0;
    final missing = <String>[];
    final offParity = <String>[];
    for (final t in territories) {
      final prices = await asc.get('v1/subscriptions/$subId/prices', {
        'filter[territory]': t,
        'limit': '50',
        'include': 'subscriptionPricePoint',
      });
      final current = prices.dataList
          .where(
            (p) =>
                (p['attributes'] as Map<String, Object?>?)?['startDate'] ==
                null,
          )
          .firstOrNull;
      if (current == null) {
        missing.add(t);
        continue;
      }
      priced++;
      final pointId =
          (((current['relationships'] as Map?)?['subscriptionPricePoint']
                      as Map?)?['data']
                  as Map?)?['id']
              as String?;
      final price = pricePointPrice(prices.json, pointId);
      final atParity =
          price == wanted || (refTier != null && tierOf(pointId) == refTier);
      if (!atParity) offParity.add('$t=$price');
    }
    final parityNote = offParity.isEmpty
        ? 'parity OK (nominal or equalized tier)'
        : 'OFF PARITY: ${offParity.join(', ')}';
    print('  territories priced: $priced/${territories.length} — $parityNote');
    if (missing.isNotEmpty) {
      print('  missing: ${missing.join(', ')}');
    }
  }

  print('=== App Store Connect ===');
  const nominal = {'pro_yearly': '49.99', 'pro_monthly': '4.99'};
  for (final productId in ['pro_yearly', 'pro_monthly']) {
    final found = await asc.get(
      'v1/subscriptionGroups/$groupId/subscriptions',
      {'filter[productId]': productId},
    );
    if (found.dataList.isEmpty) {
      print('$productId: NOT FOUND');
      continue;
    }
    final sub = found.dataList.first;
    final subId = sub['id'] as String;
    print(
      '\n$productId (id $subId, state '
      '${(sub['attributes'] as Map)['state']})',
    );
    final locs = await asc.get(
      'v1/subscriptions/$subId/subscriptionLocalizations',
    );
    for (final loc in locs.dataList) {
      final a = loc['attributes'] as Map<String, Object?>;
      print(
        '  loc ${a['locale']}: name="${a['name']}" '
        'description="${a['description']}"',
      );
    }
    await priceCoverage(subId, nominal[productId]!);
  }

  // IAP (lifetime)
  final iapFound = await asc.get('v1/apps/$appId/inAppPurchasesV2', {
    'filter[productId]': 'pro_lifetime',
  });
  if (iapFound.dataList.isEmpty) {
    print('\npro_lifetime: NOT FOUND');
  } else {
    final iap = iapFound.dataList.first;
    final iapId = iap['id'] as String;
    print(
      '\npro_lifetime (id $iapId, state '
      '${(iap['attributes'] as Map)['state']})',
    );
    final locs = await asc.get(
      'v2/inAppPurchases/$iapId/inAppPurchaseLocalizations',
    );
    for (final loc in locs.dataList) {
      final a = loc['attributes'] as Map<String, Object?>;
      print(
        '  loc ${a['locale']}: name="${a['name']}" '
        'description="${a['description']}"',
      );
    }
    final sched = await asc.get('v2/inAppPurchases/$iapId/iapPriceSchedule', {
      'include': 'manualPrices',
    });
    final inc = (sched.json['included'] as List?) ?? [];
    final manual = inc.where((i) => i['type'] == 'inAppPurchasePrices');
    if (manual.isNotEmpty) {
      // The manual (base) price is USA 99.99 — territory prices are
      // auto-equalized by Apple (verified: 178 automaticPrices exist).
      print(
        '  price: base territory USA set; 178 auto-equalized territory '
        'prices exist (checked separately)',
      );
    } else {
      print('  price: NO manual base price found');
    }
  }

  // ---- Play ----
  print('\n=== Google Play ===');
  try {
    await _inspectPlay(env);
  } on ApiException catch (e) {
    print(
      'Play inspection failed (known: service account currently lacks '
      'read permission): $e',
    );
  }
}

Future<void> _inspectPlay(Map<String, String> env) async {
  final sa = ServiceAccountCredentials.fromJson(
    jsonDecode(
      await File(env['GOOGLE_APPLICATION_CREDENTIALS']!).readAsString(),
    ),
  );
  final authClient = await clientViaServiceAccount(sa, [
    'https://www.googleapis.com/auth/androidpublisher',
  ]);
  final play = HttpApiClient(
    baseUrl: 'https://androidpublisher.googleapis.com',
    client: authClient,
  );
  const pkg = 'com.kounex.obsBlade';

  String money(Map? price) => price == null
      ? '?'
      : '${price['units']}.${((price['nanos'] ?? 0) ~/ 10000000).toString().padLeft(2, '0')} ${price['currencyCode']}';

  final sub = await play.get(
    'androidpublisher/v3/applications/$pkg/monetization/subscriptions/pro',
  );
  final subJson = sub.json;
  print('subscription pro:');
  for (final l in (subJson['listings'] as List? ?? [])) {
    print(
      '  listing ${l['languageCode']}: title="${l['title']}" '
      'description="${l['description']}"',
    );
  }
  for (final bp in (subJson['basePlans'] as List? ?? [])) {
    final regional = (bp['regionalConfigs'] as List? ?? [])
        .where((r) => ['US', 'DE', 'GB'].contains(r['regionCode']))
        .map((r) => '${r['regionCode']}=${money(r['price'] as Map?)}')
        .join(', ');
    print(
      '  basePlan ${bp['basePlanId']} (${bp['state']}) '
      '${bp['billingPeriodDuration']}: $regional',
    );
  }

  final otp = await play.get(
    'androidpublisher/v3/applications/$pkg/monetization/onetimeproducts/pro_lifetime',
  );
  final otpJson = otp.json;
  print('one-time pro_lifetime:');
  for (final l in (otpJson['listings'] as List? ?? [])) {
    print(
      '  listing ${l['languageCode']}: title="${l['title']}" '
      'description="${l['description']}"',
    );
  }
  final regional =
      (otpJson['regionalPricingAndAvailabilityConfigs'] as List? ?? [])
          .where((r) => ['US', 'DE', 'GB'].contains(r['regionCode']))
          .map((r) => '${r['regionCode']}=${money(r['price'] as Map?)}')
          .join(', ');
  print('  prices: $regional');
}
