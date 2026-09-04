import 'dart:convert';

import 'package:provisioning/src/asc_jwt.dart';
import 'package:test/test.dart';

// Throwaway P-256 key generated for this test only (openssl ecparam
// -name prime256v1 -genkey | openssl pkcs8 -topk8 -nocrypt). Not used
// anywhere else; the test asserts claims/header shape, not a signature.
const _testPrivateKeyPem = '''
-----BEGIN PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQg79wrsp6N7CSOq9oj
aplDYT27JyJjIYQkyyaUpHwayWuhRANCAATAzf+NB27TpZzmid80uV5NZu1As8jr
sdLrqOkhJGYxGKV3Ra6ngVAXNFRz3YMv7ECtAHTi62P5pcnQCzJm4pBg
-----END PRIVATE KEY-----
''';

Map<String, Object?> _decodeSegment(String segment) =>
    jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(segment))))
        as Map<String, Object?>;

void main() {
  test('ASC JWT has the required header and claims shape', () {
    final now = DateTime.utc(2026, 9, 4, 12);
    final token = buildAscJwt(
      privateKeyPem: _testPrivateKeyPem,
      keyId: 'ABC123DEFG',
      issuerId: '69a6de7c-1234-47e3-e053-5b8c7c11a4d1',
      now: now,
    );

    final parts = token.split('.');
    expect(parts, hasLength(3));

    final header = _decodeSegment(parts[0]);
    expect(header['alg'], 'ES256');
    expect(header['kid'], 'ABC123DEFG');
    expect(header['typ'], 'JWT');

    final claims = _decodeSegment(parts[1]);
    expect(claims['iss'], '69a6de7c-1234-47e3-e053-5b8c7c11a4d1');
    expect(claims['aud'], 'appstoreconnect-v1');
    expect(claims['iat'], now.millisecondsSinceEpoch ~/ 1000);
    // Apple caps token lifetime at 20 minutes; we use 19.
    expect(
        claims['exp'],
        now.add(const Duration(minutes: 19)).millisecondsSinceEpoch ~/
            1000);
    // Lifetime stays within Apple's limit.
    expect(
        (claims['exp'] as int) - (claims['iat'] as int), lessThan(20 * 60));
  });
}
