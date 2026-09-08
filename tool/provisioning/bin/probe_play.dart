import 'dart:convert';
import 'dart:io';
import 'package:googleapis_auth/auth_io.dart';

Future<void> main() async {
  final env = Platform.environment;
  final sa = ServiceAccountCredentials.fromJson(
    jsonDecode(
      await File(env['GOOGLE_APPLICATION_CREDENTIALS']!).readAsString(),
    ),
  );
  final authClient = await clientViaServiceAccount(sa, [
    'https://www.googleapis.com/auth/androidpublisher',
  ]);
  const base =
      'https://androidpublisher.googleapis.com/androidpublisher/v3'
      '/applications/com.kounex.obsBlade';
  // Contrast probes: edits insert (known 200) + legacy inappproducts list.
  final edit = await authClient.post(
    Uri.parse('$base/edits'),
    headers: {'Content-Type': 'application/json'},
    body: '{}',
  );
  print('POST /edits -> ${edit.statusCode}');
  print(edit.body.length > 200 ? edit.body.substring(0, 200) : edit.body);
  print('---');
  final editId = jsonDecode(edit.body)['id'] as String?;
  final iap = await authClient.get(Uri.parse('$base/inappproducts'));
  print('GET /inappproducts -> ${iap.statusCode}');
  print(iap.body.length > 200 ? iap.body.substring(0, 200) : iap.body);
  print('---');
  for (final p in [
    '/subscriptions',
    '/subscriptions/pro',
    '/oneTimeProducts/pro_lifetime',
  ]) {
    final res = await authClient.get(Uri.parse('$base$p'));
    print('GET $p -> ${res.statusCode}');
    print('  content-type: ${res.headers['content-type']}');
    print('  server: ${res.headers['server']}');
    final b = res.body;
    if (b.startsWith('<!')) {
      print('  HTML: ${b.substring(0, b.length > 300 ? 300 : b.length)}');
    } else {
      print(const JsonEncoder.withIndent(' ').convert(jsonDecode(b)));
    }
    print('---');
  }
  // Shape probe: Google's per-region converted prices for a USD nominal.
  final conv = await authClient.post(
    Uri.parse('$base/pricing:convertRegionPrices'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'price': {'currencyCode': 'USD', 'units': '4', 'nanos': 990000000},
    }),
  );
  print('POST /pricing:convertRegionPrices -> ${conv.statusCode}');
  final convJson = jsonDecode(conv.body) as Map<String, Object?>;
  print('  top-level keys: ${convJson.keys.toList()}');
  print('  regionVersion: ${convJson['regionVersion']}');
  final regions =
      (convJson['convertedRegionPrices'] as Map<String, Object?>?) ?? {};
  print('  regions: ${regions.length}');
  for (final r in ['US', 'DE', 'GB', 'JP', 'CH', 'KR', 'IN']) {
    print('  $r: ${regions[r]}');
  }
  if (editId != null) {
    final del = await authClient.delete(Uri.parse('$base/edits/$editId'));
    print('DELETE /edits/$editId -> ${del.statusCode} (cleanup)');
  }
}
