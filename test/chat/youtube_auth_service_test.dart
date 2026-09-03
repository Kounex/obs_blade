import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/types/classes/youtube/youtube_device_code.dart';
import 'package:obs_blade/utils/youtube/youtube_auth_service.dart';

const kTestDeviceCode = YouTubeDeviceCode(
  deviceCode: 'dev-code-123',
  userCode: 'ABCD-EFGH',
  verificationUrl: 'https://www.google.com/device',
  expiresIn: 1800,
  interval: 5,
);

void main() {
  YouTubeAuthService serviceWith(MockClient client) =>
      YouTubeAuthService(client: client, sleep: (_) async {});

  group('requestDeviceCode', () {
    test('parses the device code response (verification_url)', () async {
      final client = MockClient((request) async {
        expect(
          request.url.toString(),
          'https://oauth2.googleapis.com/device/code',
        );
        expect(request.bodyFields['client_id'], kYouTubeOAuthClientId);
        expect(
          request.bodyFields['scope'],
          'https://www.googleapis.com/auth/youtube',
        );
        return http.Response(
          json.encode({
            'device_code': 'dev-code-123',
            'user_code': 'ABCD-EFGH',
            'verification_url': 'https://www.google.com/device',
            'expires_in': 1800,
            'interval': 5,
          }),
          200,
        );
      });

      final code = await serviceWith(client).requestDeviceCode();

      expect(code.deviceCode, 'dev-code-123');
      expect(code.userCode, 'ABCD-EFGH');
      expect(code.verificationUrl, 'https://www.google.com/device');
      expect(code.interval, 5);
      expect(code.expiresIn, 1800);
    });

    test('throws on non-200', () {
      final client = MockClient((request) async => http.Response('nope', 400));

      expect(
        serviceWith(client).requestDeviceCode(),
        throwsA(isA<YouTubeAuthException>()),
      );
    });
  });

  group('pollForToken', () {
    test('returns the token after pending responses', () async {
      var tokenCalls = 0;
      final client = MockClient((request) async {
        tokenCalls++;
        expect(request.url.toString(), 'https://oauth2.googleapis.com/token');
        expect(request.bodyFields['client_id'], kYouTubeOAuthClientId);
        expect(request.bodyFields['code'], 'dev-code-123');
        expect(
          request.bodyFields['grant_type'],
          'urn:ietf:params:oauth:grant-type:device_code',
        );
        if (tokenCalls < 3) {
          return http.Response(
            json.encode({'error': 'authorization_pending'}),
            400,
          );
        }
        return http.Response(
          json.encode({
            'access_token': 'access-1',
            'refresh_token': 'refresh-1',
            'expires_in': 3600,
            'scope': 'https://www.googleapis.com/auth/youtube',
            'token_type': 'Bearer',
          }),
          200,
        );
      });

      final token = await serviceWith(client).pollForToken(
        kTestDeviceCode,
        onPending: () {},
        isCancelled: () => false,
      );

      expect(token.accessToken, 'access-1');
      expect(token.refreshToken, 'refresh-1');
      expect(token.scope, ['https://www.googleapis.com/auth/youtube']);
      expect(tokenCalls, 3);
    });

    test('slow_down keeps polling instead of failing', () async {
      var tokenCalls = 0;
      final client = MockClient((request) async {
        tokenCalls++;
        if (tokenCalls == 1) {
          return http.Response(json.encode({'error': 'slow_down'}), 400);
        }
        return http.Response(
          json.encode({
            'access_token': 'access-2',
            'refresh_token': 'refresh-2',
            'expires_in': 3600,
            'scope': 'https://www.googleapis.com/auth/youtube',
          }),
          200,
        );
      });

      final token = await serviceWith(client).pollForToken(
        kTestDeviceCode,
        onPending: () {},
        isCancelled: () => false,
      );

      expect(token.accessToken, 'access-2');
      expect(tokenCalls, 2);
    });

    test('access_denied throws', () {
      final client = MockClient(
        (request) async =>
            http.Response(json.encode({'error': 'access_denied'}), 400),
      );

      expect(
        serviceWith(client).pollForToken(
          kTestDeviceCode,
          onPending: () {},
          isCancelled: () => false,
        ),
        throwsA(isA<YouTubeAuthException>()),
      );
    });

    test('expired_token throws', () {
      final client = MockClient(
        (request) async =>
            http.Response(json.encode({'error': 'expired_token'}), 400),
      );

      expect(
        serviceWith(client).pollForToken(
          kTestDeviceCode,
          onPending: () {},
          isCancelled: () => false,
        ),
        throwsA(isA<YouTubeAuthException>()),
      );
    });

    test('cancellation aborts polling', () {
      final client = MockClient(
        (request) async =>
            http.Response(json.encode({'error': 'authorization_pending'}), 400),
      );

      expect(
        serviceWith(client).pollForToken(
          kTestDeviceCode,
          onPending: () {},
          isCancelled: () => true,
        ),
        throwsA(isA<YouTubeAuthException>()),
      );
    });
  });

  group('refreshToken', () {
    test(
      'parses the refreshed token; keeps working without a new refresh token',
      () async {
        final client = MockClient((request) async {
          expect(request.bodyFields['grant_type'], 'refresh_token');
          expect(request.bodyFields['refresh_token'], 'old-refresh');
          expect(request.bodyFields['client_id'], kYouTubeOAuthClientId);
          return http.Response(
            json.encode({
              'access_token': 'access-new',
              'expires_in': 3600,
              'scope': 'https://www.googleapis.com/auth/youtube',
            }),
            200,
          );
        });

        final token = await serviceWith(client).refreshToken('old-refresh');

        expect(token.accessToken, 'access-new');

        /// Google usually does NOT return a new refresh token on refresh —
        /// callers must keep the stored one.
        expect(token.refreshToken, isNull);
      },
    );

    test('throws on 400 (revoked/expired refresh token)', () {
      final client = MockClient(
        (request) async =>
            http.Response(json.encode({'error': 'invalid_grant'}), 400),
      );

      expect(
        serviceWith(client).refreshToken('old-refresh'),
        throwsA(isA<YouTubeAuthException>()),
      );
    });
  });

  group('revoke', () {
    test('posts the token as a query parameter and never throws', () async {
      final client = MockClient((request) async {
        expect(
          request.url.toString(),
          'https://oauth2.googleapis.com/revoke?token=access-1',
        );
        return http.Response('', 200);
      });

      await serviceWith(client).revoke('access-1');
    });

    test('swallows network errors (best effort)', () async {
      final client = MockClient((request) async => throw Exception('down'));

      await serviceWith(client).revoke('access-1');
    });
  });

  group('client id resolution', () {
    test('falls back to the constant when the settings box is not open', () {
      expect(
        serviceWith(
          MockClient((request) async => http.Response('', 200)),
        ).resolveClientId(),
        kYouTubeOAuthClientId,
      );
    });
  });
}
