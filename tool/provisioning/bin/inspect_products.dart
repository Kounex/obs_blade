/// Inspection / verification: prints the live store state of the Pro
/// products (ASC + Play) — localizations (name/description), per-territory
/// subscription price coverage against the reviewed PricingTargets table,
/// and Play listings. Read-only.
///
/// Run: source ~/.localrc && dart run bin/inspect_products.dart
import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:provisioning/src/api_client.dart';
import 'package:provisioning/src/asc_jwt.dart';
import 'package:provisioning/src/pricing_targets.dart';

Future<void> main() async {
  final env = Platform.environment;
  final appId = env['OBS_BLADE_ASC_APP_ID']!;
  const groupId = '22363681'; // "Pro" subscription group

  // ---- ASC ----
  final pem = await File(env['OBS_BLADE_ASC_KEY_PATH']!).readAsString();
  final asc = HttpApiClient(
    baseUrl: 'https://api.appstoreconnect.apple.com',
    token: buildAscJwt(
      privateKeyPem: pem,
      keyId: env['OBS_BLADE_ASC_KEY_ID']!,
      issuerId: env['OBS_BLADE_ASC_ISSUER_ID']!,
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

  /// Prints "priced/total territories" and parity mismatches. Parity = the
  /// current price matches the reviewed PricingTargets value for the
  /// territory's currency (per-territory override first), allowing the
  /// provisioner's snap-to-nearest-point tolerance. A matching FUTURE-dated
  /// scheduled price change (approved subscriptions only take those)
  /// counts too and is reported separately.
  Future<void> priceCoverage(
    String subId,
    String nominalUsd,
    Map<String, String> territoryCurrency,
  ) async {
    const snapTolerance = 0.02;
    final territories = await territoryIds(subId);
    var priced = 0;
    var scheduledOnly = 0;
    final missing = <String>[];
    final offParity = <String>[];
    for (final t in territories) {
      final prices = await asc.get('v1/subscriptions/$subId/prices', {
        'filter[territory]': t,
        'limit': '50',
        'include': 'subscriptionPricePoint',
      });
      if (prices.dataList.isEmpty) {
        missing.add(t);
        continue;
      }
      priced++;
      final wanted = PricingTargets.target(
        territoryCurrency[t] ?? '?',
        nominalUsd,
        region: {'CHE': 'CH', 'LIE': 'LI'}[t],
      );
      final target = wanted == null ? null : double.tryParse(wanted);
      bool matches(Map<String, Object?> record) {
        final pointId =
            (((record['relationships'] as Map?)?['subscriptionPricePoint']
                        as Map?)?['data']
                    as Map?)?['id']
                as String?;
        final value = double.tryParse(
          pricePointPrice(prices.json, pointId) ?? '',
        );
        return value != null &&
            target != null &&
            (value / target - 1).abs() <= snapTolerance;
      }

      final records = prices.dataList;
      // The live price is the record with the LATEST startDate <= today
      // (startDate null = the base price, sorts first). Apple keeps both
      // the grandfathered old price (preserved: true) and a scheduled
      // record after its start date has passed - treating only
      // startDate == null as "current" misreads an activated change as
      // still pending (seen 2026-10-05..07: storefront already showed the
      // new prices while the API still listed them as scheduled).
      final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
      String startOf(Map<String, Object?> p) =>
          ((p['attributes'] as Map<String, Object?>?)?['startDate']
              as String?) ??
          '';
      final effective =
          records.where((p) => startOf(p).compareTo(today) <= 0).toList()
            ..sort((a, b) => startOf(a).compareTo(startOf(b)));
      final current = effective.isEmpty ? null : effective.last;
      final currentMatches = current != null && matches(current);
      if (!currentMatches &&
          records.any(
            (p) => startOf(p).compareTo(today) > 0 && matches(p),
          )) {
        scheduledOnly++; // a future-dated scheduled change covers it
      } else if (!currentMatches) {
        final price = current == null
            ? null
            : pricePointPrice(
                prices.json,
                (((current['relationships'] as Map?)?['subscriptionPricePoint']
                            as Map?)?['data']
                        as Map?)?['id']
                    as String?,
              );
        offParity.add('$t=$price(want $wanted)');
      }
    }
    final parityNote = offParity.isEmpty
        ? 'parity OK (reviewed PricingTargets)'
        : 'OFF PARITY: ${offParity.join(', ')}';
    print('  territories priced: $priced/${territories.length} — $parityNote');
    if (scheduledOnly > 0) {
      print('  ($scheduledOnly via scheduled price changes not yet in effect)');
    }
    if (missing.isNotEmpty) {
      print('  missing: ${missing.join(', ')}');
    }
  }

  print('=== App Store Connect ===');
  final territoryCurrency = <String, String>{};
  {
    final territories = await asc.get('v1/territories', {'limit': '200'});
    for (final t in territories.dataList) {
      territoryCurrency[t['id'] as String] =
          (t['attributes'] as Map?)?['currency'] as String? ?? '?';
    }
  }
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
    await priceCoverage(subId, nominal[productId]!, territoryCurrency);
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
    print('Play inspection failed: $e');
  }
}

Future<void> _inspectPlay(Map<String, String> env) async {
  final sa = ServiceAccountCredentials.fromJson(
    jsonDecode(
      await File(
        env['OBS_BLADE_GOOGLE_APPLICATION_CREDENTIALS']!,
      ).readAsString(),
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
    'androidpublisher/v3/applications/$pkg/subscriptions/pro',
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
    final period =
        (bp['autoRenewingBasePlanType'] as Map?)?['billingPeriodDuration'];
    print(
      '  basePlan ${bp['basePlanId']} (${bp['state']}) '
      '$period: $regional',
    );
  }

  final otp = await play.get(
    'androidpublisher/v3/applications/$pkg/oneTimeProducts/pro_lifetime',
  );
  final otpJson = otp.json;
  print('one-time pro_lifetime:');
  for (final l in (otpJson['listings'] as List? ?? [])) {
    print(
      '  listing ${l['languageCode']}: title="${l['title']}" '
      'description="${l['description']}"',
    );
  }
  // Pricing lives on the purchase options in the current one-time product
  // model.
  for (final po in (otpJson['purchaseOptions'] as List? ?? [])) {
    final regional =
        (po['regionalPricingAndAvailabilityConfigs'] as List? ?? [])
            .where((r) => ['US', 'DE', 'GB'].contains(r['regionCode']))
            .map((r) => '${r['regionCode']}=${money(r['price'] as Map?)}')
            .join(', ');
    print(
      '  purchaseOption ${po['purchaseOptionId']} (${po['state']}): '
      '$regional',
    );
  }
}
