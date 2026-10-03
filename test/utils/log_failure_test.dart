import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/utils/general_helper.dart';
import 'package:obs_blade/utils/kick/kick_auth_service.dart';
import 'package:obs_blade/utils/youtube/youtube_auth_service.dart';

void main() {
  group('describeError', () {
    test('typed service errors: message + status, never the body', () {
      const error = YouTubeAuthException(
        'Fetching the YouTube channel failed (403)',
        cause: '{"error": {"message": "secret body with a chat line"}}',
        statusCode: 403,
      );
      final text = GeneralHelper.describeError(error);
      expect(text, contains('Fetching the YouTube channel failed (403)'));
      expect(text, contains('HTTP 403'));
      expect(text, isNot(contains('secret body')));
    });

    test('tokens and secrets are masked in untyped errors', () {
      final text = GeneralHelper.describeError(
        Exception(
          'Bearer ya29.a0AfH6SMBx1234567890abcdef access_token=abc123 '
          '"client_secret": "s3cr3t" key=AIzaSyD-0123456789abcdefghijklmnopqrstuv',
        ),
      );
      expect(text, isNot(contains('ya29.a0AfH6SMBx')));
      expect(text, isNot(contains('abc123')));
      expect(text, isNot(contains('s3cr3t')));
      expect(text, isNot(contains('AIzaSyD')));
      expect(text, contains('<redacted>'));
    });

    test('long opaque strings are masked, long text is cut', () {
      final text = GeneralHelper.describeError(
        Exception('${'Q' * 48} ${'word ' * 100}'),
      );
      expect(text, isNot(contains('Q' * 48)));
      expect(text.length, lessThanOrEqualTo(301));
    });

    test('Kick errors use their message too', () {
      final text = GeneralHelper.describeError(
        const KickAuthException('Kick login failed (401)', statusCode: 401),
      );
      expect(text, contains('Kick login failed (401)'));
      expect(text, contains('HTTP 401'));
    });
  });

  group('logFailure', () {
    setUp(GeneralHelper.resetFailureLog);

    List<String> capture(void Function() body) {
      final lines = <String>[];
      final spec = ZoneSpecification(
        print: (self, parent, zone, line) => lines.add(line),
      );
      Zone.current.fork(specification: spec).run(body);
      return lines;
    }

    test('first failure of a kind goes to the app log, repeats within the '
        'interval only to the console', () {
      final start = DateTime(2026, 10, 3, 12);
      final lines = capture(() {
        GeneralHelper.logFailure(
          'YouTube chat poll failed',
          'boom',
          now: start,
        );
        GeneralHelper.logFailure(
          'YouTube chat poll failed',
          'boom',
          now: start.add(const Duration(minutes: 1)),
        );
        GeneralHelper.logFailure(
          'YouTube chat poll failed',
          'boom',
          now: start.add(const Duration(minutes: 6)),
        );
      });
      expect(lines.where((l) => l.contains('[ON]')), hasLength(2));
      expect(lines.where((l) => l.contains('[OFF]')), hasLength(1));
      expect(lines.first, startsWith('[WARNING][ON] YouTube chat poll failed'));
    });
  });
}
