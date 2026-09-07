import 'dart:convert';
import 'dart:io';
import 'package:googleapis_auth/auth_io.dart';

Future<void> main() async {
  final env = Platform.environment;
  final sa = ServiceAccountCredentials.fromJson(jsonDecode(
      await File(env['GOOGLE_APPLICATION_CREDENTIALS']!).readAsString()));
  final authClient = await clientViaServiceAccount(
      sa, ['https://www.googleapis.com/auth/androidpublisher']);
  const base = 'https://androidpublisher.googleapis.com/androidpublisher/v3'
      '/applications/com.kounex.obsBlade';
  for (final p in [
    '/monetization/subscriptions',
    '/monetization/subscriptions/pro',
    '/monetization/onetimeproducts/pro_lifetime',
  ]) {
    final res = await authClient.get(Uri.parse('$base$p'));
    print('GET $p -> ${res.statusCode}');
    final b = res.body;
    print(b.startsWith('<!') ? '(HTML 404 page)' : const JsonEncoder.withIndent(' ').convert(jsonDecode(b)));
    print('---');
  }
}
