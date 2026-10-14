import 'package:flutter_test/flutter_test.dart';

import '../../tool/release_checks.dart';

void main() {
  group('forbiddenDefines', () {
    test('client id alone is fine', () {
      expect(forbiddenDefines('{"KICK_OAUTH_CLIENT_ID": "abc"}'), isEmpty);
    });

    test('a non-empty secret is refused', () {
      expect(
        forbiddenDefines(
          '{"KICK_OAUTH_CLIENT_ID": "abc", "KICK_OAUTH_CLIENT_SECRET": "s"}',
        ),
        ['KICK_OAUTH_CLIENT_SECRET'],
      );
    });

    test('an empty secret is fine', () {
      expect(forbiddenDefines('{"KICK_OAUTH_CLIENT_SECRET": " "}'), isEmpty);
    });

    test('the dogfood Pro unlock is refused', () {
      expect(
        forbiddenDefines('{"PRO_RELEASE_TEST_UNLOCK": "true"}'),
        ['PRO_RELEASE_TEST_UNLOCK'],
      );
    });

    test('not a JSON object: nothing to refuse', () {
      expect(forbiddenDefines('[]'), isEmpty);
    });
  });
}
