/// Pricing audit (read-only): cross-checks every territory's LIVE Pro price
/// on both stores against three independent references —
///
///   1. Google's `pricing:convertRegionPrices` table (FX-current, tax-aware,
///      market-rounded — the candidate single pricing source),
///   2. Apple's equalized price tier (the App Store price matrix; detects
///      frozen/stale currencies like TRY),
///   3. an independent FX rate (open.er-api.com, USD base),
///
/// and flags outliers so no territory silently sits at an absurd price
/// (the 2026-10 nominal-parity bug priced TRY/EGP/ZAR/… at a literal 4.99).
/// Ends with a proposed per-currency target table (anchor currencies at the
/// USD/EUR/GBP nominal, everything else at Google's converted price).
///
/// Nothing is written — this is the review gate before any pricing run and
/// the drift detector for the quarterly re-pricing cadence.
///
/// Run: source ~/.localrc && dart run bin/audit_prices.dart
import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:provisioning/src/api_client.dart';
import 'package:provisioning/src/asc_jwt.dart';

/// Currencies priced at the USD nominal on purpose ($/€/£ 4.99-49.99-99.99)
/// — not flagged even when the conversion tables differ.
const anchorCurrencies = {'USD', 'EUR', 'GBP'};

/// Deviation (live vs Google's table, in USD terms) above which a currency
/// is reported as an outlier.
const outlierThreshold = 0.20;

/// The Apple tier (`p` field) embedded in a base64url price-point id.
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

/// region/territory → (currency, price) value used across the audit.
typedef PriceMap = Map<String, String>;

void main() async {
  final env = Platform.environment;
  final pem = await File(env['OBS_BLADE_ASC_KEY_PATH']!).readAsString();
  final asc = HttpApiClient(
    baseUrl: 'https://api.appstoreconnect.apple.com',
    token: buildAscJwt(
      privateKeyPem: pem,
      keyId: env['OBS_BLADE_ASC_KEY_ID']!,
      issuerId: env['OBS_BLADE_ASC_ISSUER_ID']!,
    ),
  );
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

  // ---- FX (independent reference) ----
  final fxBody = jsonDecode(
    (await http.get(Uri.parse('https://open.er-api.com/v6/latest/USD'))).body,
  );
  if (fxBody['result'] != 'success') {
    stderr.writeln('FX fetch failed: $fxBody');
    exitCode = 1;
    return;
  }
  final fx = (fxBody['rates'] as Map).map(
    (k, v) => MapEntry(k as String, (v as num).toDouble()),
  );
  print('FX: open.er-api.com USD base, ${fxBody['time_last_update_utc']}');

  double? usd(String? price, String currency) {
    if (price == null) return null;
    final rate = fx[currency];
    final value = double.tryParse(price);
    return rate == null || value == null ? null : value / rate;
  }

  String fmt(String? price, String currency, {double? ref}) {
    if (price == null) return '—';
    final u = usd(price, currency);
    final base = '$price (\$${u?.toStringAsFixed(2) ?? '?'})';
    if (ref == null || u == null) return base;
    final dev = u / ref - 1;
    final flag = dev.abs() > outlierThreshold ? ' ⚠' : '';
    return '$base ${dev >= 0 ? '+' : ''}${(dev * 100).round()}%$flag';
  }

  String money(Map p) {
    final nanos = (p['nanos'] as num?) ?? 0;
    return '${p['units']}'
        '${nanos > 0 ? '.${(nanos ~/ 10000000).toString().padLeft(2, '0')}' : ''}';
  }

  // ---- Territory → currency (ASC) ----
  final territoryCurrency = <String, String>{};
  {
    final territories = await asc.get('v1/territories', {'limit': '200'});
    for (final t in territories.dataList) {
      territoryCurrency[t['id'] as String] =
          (t['attributes'] as Map?)?['currency'] as String? ?? '?';
    }
  }

  // ---- Google convertRegionPrices: region → {currency, price} ----
  Future<Map<String, Map<String, String>>> googleTable(String usdPrice) async {
    final parts = usdPrice.split('.');
    final res = await play.post(
      'androidpublisher/v3/applications/$pkg/pricing:convertRegionPrices',
      {
        'price': {
          'currencyCode': 'USD',
          'units': parts[0],
          'nanos': int.parse('${parts[1]}0000000'),
        },
      },
    );
    final converted =
        (res.json['convertedRegionPrices'] as Map<String, Object?>?) ?? {};
    final out = <String, Map<String, String>>{};
    for (final entry in converted.entries) {
      final p = (entry.value as Map?)?['price'] as Map<String, Object?>?;
      if (p == null) continue;
      out[entry.key] = {
        'currency': p['currencyCode'] as String,
        'price': money(p),
      };
    }
    return out;
  }

  /// currency → price when every region using the currency agrees; conflicts
  /// (e.g. EUR differing per country by VAT) are listed separately.
  Map<String, String> uniqueByCurrency(
    Map<String, Map<String, String>> table,
    Map<String, Set<String>> conflicts,
  ) {
    final byCurrency = <String, Set<String>>{};
    for (final region in table.values) {
      byCurrency
          .putIfAbsent(region['currency']!, () => {})
          .add(region['price']!);
    }
    final out = <String, String>{};
    for (final entry in byCurrency.entries) {
      if (entry.value.length == 1) {
        out[entry.key] = entry.value.single;
      } else {
        conflicts[entry.key] = entry.value;
      }
    }
    return out;
  }

  // ---- Play GETs with 503 retry ----
  Future<ApiResponse> playGet(String path) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        return await play.get(path);
      } on ApiException catch (e) {
        if (e.statusCode != 503 || attempt == 2) rethrow;
        await Future<void>.delayed(const Duration(seconds: 10));
      }
    }
    throw StateError('unreachable');
  }

  // ---- Live Play prices: region → price ----
  Future<PriceMap> playSubPrices(String basePlanId) async {
    final sub = await playGet(
      'androidpublisher/v3/applications/$pkg/subscriptions/pro',
    );
    final out = <String, String>{};
    for (final bp
        in (sub.json['basePlans'] as List? ?? const []).whereType<Map>()) {
      if (bp['basePlanId'] != basePlanId) continue;
      for (final rc
          in (bp['regionalConfigs'] as List? ?? const []).whereType<Map>()) {
        final p = rc['price'] as Map?;
        if (p != null) out[rc['regionCode'] as String] = money(p);
      }
    }
    return out;
  }

  Future<PriceMap> playLifetimePrices() async {
    final otp = await playGet(
      'androidpublisher/v3/applications/$pkg/oneTimeProducts/pro_lifetime',
    );
    final out = <String, String>{};
    for (final po
        in (otp.json['purchaseOptions'] as List? ?? const [])
            .whereType<Map>()) {
      for (final rc
          in (po['regionalPricingAndAvailabilityConfigs'] as List? ?? const [])
              .whereType<Map>()) {
        final p = rc['price'] as Map?;
        if (p != null) out[rc['regionCode'] as String] = money(p);
      }
    }
    return out;
  }

  // ---- ASC helpers ----
  Future<List<Map<String, Object?>>> allPoints(
    String subId,
    String territory,
  ) async {
    final out = <Map<String, Object?>>[];
    String? cursor;
    do {
      final page = await asc.get('v1/subscriptions/$subId/pricePoints', {
        'filter[territory]': territory,
        'limit': '200',
        if (cursor != null) 'cursor': cursor,
      });
      out.addAll(page.dataList);
      final meta = page.json['meta'];
      final paging = meta is Map ? meta['paging'] : null;
      cursor = paging is Map ? paging['nextCursor'] as String? : null;
    } while (cursor != null);
    return out;
  }

  Future<String?> referenceTier(String subId, String nominalUsd) async {
    for (final p in await allPoints(subId, 'USA')) {
      if ((p['attributes'] as Map?)?['customerPrice'] == nominalUsd) {
        return tierOf(p['id'] as String?);
      }
    }
    return null;
  }

  /// The equalized-tier price of [tier] per currency (one representative
  /// territory per currency — territories sharing a currency share the tier
  /// price).
  Future<PriceMap> tierPriceByCurrency(String subId, String tier) async {
    final representative = <String, String>{};
    for (final entry in territoryCurrency.entries) {
      representative.putIfAbsent(entry.value, () => entry.key);
    }
    final out = <String, String>{};
    final target = int.tryParse(tier);
    for (final entry in representative.entries) {
      for (final p in await allPoints(subId, entry.value)) {
        final pointTier = int.tryParse(tierOf(p['id'] as String?) ?? '');
        if (pointTier == null) continue;
        if (pointTier.toString() == tier) {
          out[entry.key] =
              (p['attributes'] as Map?)?['customerPrice'] as String? ?? '?';
          break;
        }
        if (target != null && pointTier > target) break; // tiers ascend
      }
    }
    return out;
  }

  /// Live per-territory subscription prices: territory → customerPrice.
  /// The live price is the record with the latest startDate <= today
  /// (startDate null = base price, sorts first) - Apple keeps the
  /// grandfathered old price AND the scheduled record after activation,
  /// so a past-dated scheduled record IS the live price (verified against
  /// the storefront 2026-10-07). A pending FUTURE-dated change wins over
  /// the current price: it's the price new buyers will actually pay once
  /// it takes effect.
  Future<PriceMap> appleSubPrices(String subId) async {
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
    final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    final out = <String, String>{};
    for (final t in ids) {
      final prices = await asc.get('v1/subscriptions/$subId/prices', {
        'filter[territory]': t,
        'limit': '50',
        'include': 'subscriptionPricePoint',
      });
      Map<String, Object?>? chosen;
      var chosenDate = '';
      Map<String, Object?>? future;
      var futureDate = '';
      for (final p in prices.dataList) {
        final startDate =
            (p['attributes'] as Map<String, Object?>?)?['startDate']
                as String? ??
            '';
        if (startDate.compareTo(today) > 0) {
          if (future == null || startDate.compareTo(futureDate) > 0) {
            future = p;
            futureDate = startDate;
          }
        } else if (chosen == null || startDate.compareTo(chosenDate) > 0) {
          chosen = p;
          chosenDate = startDate;
        }
      }
      // A future-dated scheduled change still wins when one exists;
      // otherwise the latest already-effective record is the live price.
      chosen = future ?? chosen;
      if (chosen == null) continue;
      final pointId =
          (((chosen['relationships'] as Map?)?['subscriptionPricePoint']
                      as Map?)?['data']
                  as Map?)?['id']
              as String?;
      for (final inc
          in (prices.json['included'] as List? ?? const [])
              .whereType<Map<String, Object?>>()) {
        if (inc['id'] == pointId) {
          out[t] =
              (inc['attributes'] as Map?)?['customerPrice'] as String? ?? '?';
        }
      }
    }
    return out;
  }

  /// Live per-territory lifetime IAP prices from the auto-equalized
  /// schedule (territory → price), or null when the endpoint shape doesn't
  /// cooperate (reported as a note, not a failure).
  Future<PriceMap?> appleLifetimePrices(String iapId) async {
    try {
      final sched = await asc.get('v2/inAppPurchases/$iapId/iapPriceSchedule');
      final schedId = sched.dataObject?['id'] as String?;
      if (schedId == null) return null;
      final out = <String, String>{};
      String? cursor;
      do {
        final page = await asc
            .get('v1/inAppPurchasePriceSchedules/$schedId/automaticPrices', {
              'limit': '200',
              'include': 'territory,inAppPurchasePricePoint',
              if (cursor != null) 'cursor': cursor,
            });
        final included = <String, Map<String, Object?>>{};
        for (final inc
            in (page.json['included'] as List? ?? const [])
                .whereType<Map<String, Object?>>()) {
          included['${inc['type']}/${inc['id']}'] = inc;
        }
        for (final p in page.dataList) {
          final rels = p['relationships'] as Map<String, Object?>?;
          final territoryId =
              ((rels?['territory'] as Map?)?['data'] as Map?)?['id'] as String?;
          final pointId =
              ((rels?['inAppPurchasePricePoint'] as Map?)?['data']
                      as Map?)?['id']
                  as String?;
          final point = included['inAppPurchasePricePoints/$pointId'];
          final price =
              (point?['attributes'] as Map?)?['customerPrice'] as String?;
          if (territoryId != null && price != null) out[territoryId] = price;
        }
        final meta = page.json['meta'];
        final paging = meta is Map ? meta['paging'] : null;
        cursor = paging is Map ? paging['nextCursor'] as String? : null;
      } while (cursor != null);
      return out.isEmpty ? null : out;
    } on ApiException {
      return null;
    }
  }

  /// currency → set of prices, joining a region-priced map (Play/Google,
  /// ISO-2) via the Google table's region → currency.
  Map<String, Set<String>> regionPricesByCurrency(
    PriceMap regionPrices,
    Map<String, Map<String, String>> googleRaw,
  ) {
    final out = <String, Set<String>>{};
    for (final entry in regionPrices.entries) {
      final currency = googleRaw[entry.key]?['currency'];
      if (currency == null) continue;
      out.putIfAbsent(currency, () => {}).add(entry.value);
    }
    return out;
  }

  /// territory prices (ISO-3) → currency → set of prices.
  Map<String, Set<String>> territoryPricesByCurrency(PriceMap territoryPrices) {
    final out = <String, Set<String>>{};
    for (final entry in territoryPrices.entries) {
      final currency = territoryCurrency[entry.key] ?? '?';
      out.putIfAbsent(currency, () => {}).add(entry.value);
    }
    return out;
  }

  /// currencies → territories (for expanding outlier rows).
  Map<String, List<String>> territoriesByCurrency(PriceMap territoryPrices) {
    final out = <String, List<String>>{};
    for (final t in territoryPrices.keys) {
      out.putIfAbsent(territoryCurrency[t] ?? '?', () => []).add(t);
    }
    return out;
  }

  // ---- Report one product ----
  void report({
    required String label,
    required String nominalUsd,
    required PriceMap appleLive,
    required PriceMap playLive,
    required Map<String, Map<String, String>> googleRaw,
    PriceMap? appleTier,
    Map<String, Set<String>>? googleConflicts,
  }) {
    final conflicts = <String, Set<String>>{};
    final googleCur = uniqueByCurrency(googleRaw, conflicts);
    googleConflicts?.addAll(conflicts);
    final appleByCur = territoryPricesByCurrency(appleLive);
    final playByCur = regionPricesByCurrency(playLive, googleRaw);
    final byCur = territoriesByCurrency(appleLive);
    final currencies = <String>{...appleByCur.keys, ...playByCur.keys}.toList()
      ..sort();

    print('\n=== $label (USD $nominalUsd) ===');
    if (conflicts.isNotEmpty) {
      print(
        '  Google table currency conflicts: '
        '${conflicts.entries.map((e) => '${e.key}=${e.value.join('/')}').join(', ')}',
      );
    }
    final outliers = <String>[];
    final matrixIssues = <String>[];
    for (final currency in currencies) {
      final google = googleCur[currency];
      final ref = usd(google, currency);
      final anchor = anchorCurrencies.contains(currency);
      final tag = anchor ? ' [anchor]' : '';
      final territories = (byCur[currency] ?? [])..sort();
      final appleValues = appleByCur[currency] ?? {};
      final playValues = playByCur[currency] ?? {};
      final tier = appleTier?[currency];

      final appleWorst = appleValues
          .map((p) => usd(p, currency))
          .whereType<double>()
          .fold<double?>(null, (worst, v) {
            if (ref == null) return worst;
            final dev = (v / ref - 1).abs();
            return worst == null || dev > worst ? dev : worst;
          });
      final playWorst = playValues
          .map((p) => usd(p, currency))
          .whereType<double>()
          .fold<double?>(null, (worst, v) {
            if (ref == null) return worst;
            final dev = (v / ref - 1).abs();
            return worst == null || dev > worst ? dev : worst;
          });
      final isOutlier =
          !anchor &&
          ref != null &&
          ((appleWorst != null && appleWorst > outlierThreshold) ||
              (playWorst != null && playWorst > outlierThreshold));

      final line =
          '  $currency ×${territories.length}$tag: '
          'Apple ${appleValues.map((p) => fmt(p, currency, ref: ref)).join('/')} | '
          'Play ${playValues.isEmpty ? '—' : playValues.map((p) => fmt(p, currency, ref: ref)).join('/')} | '
          'Google ${fmt(google, currency)}'
          '${appleTier != null ? ' | AppleTier ${fmt(tier, currency, ref: ref)}' : ''}';
      if (isOutlier) {
        outliers.add('$line\n      → ${territories.join(', ')}');
      } else {
        print(line);
      }
      if (appleTier != null && ref != null && tier != null) {
        final tierUsd = usd(tier, currency);
        if (tierUsd != null && (tierUsd / ref - 1).abs() > outlierThreshold) {
          matrixIssues.add(
            '  $currency: AppleTier ${fmt(tier, currency, ref: ref)} '
            'vs Google ${fmt(google, currency)}',
          );
        }
      }
    }
    if (outliers.isNotEmpty) {
      print(
        '  OUTLIERS (live deviates >${(outlierThreshold * 100).round()}% '
        'from Google table):',
      );
      for (final o in outliers) {
        print(o);
      }
    }
    if (matrixIssues.isNotEmpty) {
      print(
        '  APPLE MATRIX STALE (tier vs Google '
        '>${(outlierThreshold * 100).round()}%):',
      );
      for (final m in matrixIssues) {
        print(m);
      }
    }
  }

  // ---- Collect ----
  final googleMonthly = await googleTable('4.99');
  final googleYearly = await googleTable('49.99');
  final googleLifetime = await googleTable('99.99');
  final playMonthly = await playSubPrices('pro-monthly');
  final playYearly = await playSubPrices('pro-yearly');
  final playLifetime = await playLifetimePrices();
  final appleMonthly = await appleSubPrices('6809188664');
  final appleYearly = await appleSubPrices('6809188674');
  final tierMonthly = await referenceTier('6809188664', '4.99');
  final tierYearly = await referenceTier('6809188674', '49.99');
  final tierPriceMonthly = tierMonthly == null
      ? <String, String>{}
      : await tierPriceByCurrency('6809188664', tierMonthly);
  final tierPriceYearly = tierYearly == null
      ? <String, String>{}
      : await tierPriceByCurrency('6809188674', tierYearly);
  final appleLifetime = await appleLifetimePrices('6809191613');

  // ---- Report ----
  report(
    label: 'pro_monthly',
    nominalUsd: '4.99',
    appleLive: appleMonthly,
    playLive: playMonthly,
    googleRaw: googleMonthly,
    appleTier: tierPriceMonthly,
  );
  report(
    label: 'pro_yearly',
    nominalUsd: '49.99',
    appleLive: appleYearly,
    playLive: playYearly,
    googleRaw: googleYearly,
    appleTier: tierPriceYearly,
  );
  report(
    label: 'pro_lifetime',
    nominalUsd: '99.99',
    appleLive: appleLifetime ?? {},
    playLive: playLifetime,
    googleRaw: googleLifetime,
  );
  if (appleLifetime == null) {
    print(
      '  (App Store lifetime per-territory prices could not be read — '
      'the automaticPrices endpoint shape differs; check the console.)',
    );
  }

  // ---- Proposed target table ----
  print('\n=== PROPOSED TARGETS (anchor nominal, else Google table) ===');
  final conflicts = <String, Set<String>>{};
  final targetMonthly = uniqueByCurrency(googleMonthly, conflicts);
  final targetYearly = uniqueByCurrency(googleYearly, <String, Set<String>>{});
  final targetLifetime = uniqueByCurrency(
    googleLifetime,
    <String, Set<String>>{},
  );
  final allCurrencies = <String>{...territoryCurrency.values}.toList()..sort();
  for (final currency in allCurrencies) {
    final anchor = anchorCurrencies.contains(currency);
    final m = anchor ? '4.99' : targetMonthly[currency] ?? 'CONFLICT/—';
    final y = anchor ? '49.99' : targetYearly[currency] ?? 'CONFLICT/—';
    final l = anchor ? '99.99' : targetLifetime[currency] ?? 'CONFLICT/—';
    print(
      '  $currency${anchor ? ' [anchor]' : ''}: monthly $m · yearly $y · lifetime $l'
      '${anchor ? '' : '  (=\$${usd(targetMonthly[currency], currency)?.toStringAsFixed(2) ?? '?'}/mo)'}',
    );
  }
  print(
    '  Apple writes snap each value to the nearest App Store price point; '
    'Play writes the exact value per region (per-country differences inside '
    'a currency, e.g. EUR VAT, are preserved on Play; anchor currencies stay '
    'nominal everywhere).',
  );

  authClient.close();
}
