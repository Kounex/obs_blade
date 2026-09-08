import 'dart:io';
import 'package:provisioning/src/api_client.dart';
import 'package:provisioning/src/asc_jwt.dart';

Future<void> main() async {
  final env = Platform.environment;
  final pem = await File(env['ASC_KEY_PATH']!).readAsString();
  final asc = HttpApiClient(
    baseUrl: 'https://api.appstoreconnect.apple.com',
    token: buildAscJwt(
      privateKeyPem: pem,
      keyId: env['ASC_KEY_ID']!,
      issuerId: env['ASC_ISSUER_ID']!,
    ),
  );
  for (final id in ['6809188674', '6809188664']) {
    final r = await asc.get('v1/subscriptions/$id');
    final a = r.dataObject?['attributes'] as Map<String, Object?>?;
    print('${a?['productId']}: reference name="${a?['name']}"');
  }
  final iap = await asc.get('v2/inAppPurchases/6809191613');
  final a = iap.dataObject?['attributes'] as Map<String, Object?>?;
  print('${a?['productId']}: reference name="${a?['name']}"');
}
