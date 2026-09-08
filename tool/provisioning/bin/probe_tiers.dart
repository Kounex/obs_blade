/// Diagnostic: verifies that Apple price-point tiers (the `p` field embedded
/// in the base64url point id) are consistent across territories — i.e. that
/// the tier of the USA point for a nominal USD price maps to the locally
/// conventional price elsewhere ($4.99 → ¥500, 55 kr, …).
///
/// Run: source ~/.localrc && dart run bin/probe_tiers.dart
import 'dart:convert';
import 'dart:io';

import 'package:provisioning/src/api_client.dart';
import 'package:provisioning/src/asc_jwt.dart';

String? tierOf(String id) {
  try {
    final padded = id + '=' * ((4 - id.length % 4) % 4);
    final decoded = jsonDecode(utf8.decode(base64Url.decode(padded)));
    return decoded is Map ? decoded['p'] as String? : null;
  } catch (_) {
    return null;
  }
}

Future<List<Map<String, Object?>>> allPoints(
  ApiClient asc,
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

Future<void> main() async {
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

  const subs = {'pro_monthly': '6809188664', 'pro_yearly': '6809188674'};
  const nominals = {'pro_monthly': '4.99', 'pro_yearly': '49.99'};
  const territories = ['JPN', 'SWE', 'KOR', 'IND', 'DEU', 'GBR'];

  for (final entry in subs.entries) {
    final usaPoints = await allPoints(asc, entry.value, 'USA');
    final usaPoint = usaPoints.firstWhere(
      (p) => (p['attributes'] as Map)['customerPrice'] == nominals[entry.key],
      orElse: () => {},
    );
    if (usaPoint.isEmpty) {
      print('${entry.key}: no USA ${nominals[entry.key]} point?!');
      continue;
    }
    final tier = tierOf(usaPoint['id'] as String);
    print('${entry.key}: USA ${nominals[entry.key]} → tier $tier');
    for (final t in territories) {
      final points = await allPoints(asc, entry.value, t);
      final match = points.firstWhere(
        (p) => tierOf(p['id'] as String) == tier,
        orElse: () => {},
      );
      if (match.isEmpty) {
        print(
          '  $t: NO point with tier $tier '
          '(${points.length} points scanned)',
        );
      } else {
        print(
          '  $t: tier $tier → '
          '${(match['attributes'] as Map)['customerPrice']}',
        );
      }
    }
  }
}
