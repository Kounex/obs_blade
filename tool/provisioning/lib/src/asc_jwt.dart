import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

/// Builds an App Store Connect API token (ES256 JWT) from an in-app-purchase
/// / App Store Connect API `.p8` key.
///
/// Claim/header shape per
/// https://developer.apple.com/documentation/appstoreconnectapi/generating-tokens-for-api-requests
/// - header: alg ES256, kid = key id, typ JWT (library default)
/// - claims: iss = issuer id, iat, exp (Apple caps the lifetime at 20 min;
///   we use 19 to leave clock-skew headroom), aud = "appstoreconnect-v1"
String buildAscJwt({
  required String privateKeyPem,
  required String keyId,
  required String issuerId,
  DateTime? now,
}) {
  final issuedAt = now ?? DateTime.now();
  final expires = issuedAt.add(const Duration(minutes: 19));
  final jwt = JWT(
    {
      'iss': issuerId,
      'iat': issuedAt.millisecondsSinceEpoch ~/ 1000,
      'exp': expires.millisecondsSinceEpoch ~/ 1000,
      'aud': 'appstoreconnect-v1',
    },
    header: {'kid': keyId},
  );
  return jwt.sign(
    ECPrivateKey(privateKeyPem),
    algorithm: JWTAlgorithm.ES256,
    noIssueAt: true,
  );
}
