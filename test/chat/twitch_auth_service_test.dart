import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/types/classes/twitch/twitch_device_code.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';

const kTestDeviceCode = TwitchDeviceCode(
  deviceCode: 'dev-code-123',
  userCode: 'ABCD-EFGH',
  verificationUri: 'https://www.twitch.tv/activate',
  expiresIn: 1800,
  interval: 5,
);

void main() {
  TwitchAuthService serviceWith(MockClient client) =>
      TwitchAuthService(client: client, sleep: (_) async {});

  group('requestDeviceCode', () {
    test('parses the device code response', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), 'https://id.twitch.tv/oauth2/device');
        expect(request.bodyFields['client_id'], kTwitchClientId);
        expect(request.bodyFields['scopes'],
            'user:read:chat user:write:chat user:read:emotes '
            'moderator:read:blocked_terms moderator:read:chat_settings '
            'moderator:read:unban_requests moderator:read:banned_users '
            'moderator:read:chat_messages moderator:read:warnings '
            'moderator:read:moderators moderator:read:vips');
        return http.Response(
          json.encode({
            'device_code': 'dev-code-123',
            'user_code': 'ABCD-EFGH',
            'verification_uri': 'https://www.twitch.tv/activate',
            'expires_in': 1800,
            'interval': 5,
          }),
          200,
        );
      });

      final code = await serviceWith(client).requestDeviceCode();

      expect(code.deviceCode, 'dev-code-123');
      expect(code.userCode, 'ABCD-EFGH');
      expect(code.interval, 5);
      expect(code.expiresIn, 1800);
    });

    test('throws on non-200', () {
      final client =
          MockClient((request) async => http.Response('nope', 400));

      expect(
        serviceWith(client).requestDeviceCode(),
        throwsA(isA<TwitchAuthException>()),
      );
    });
  });

  group('pollForToken', () {
    test('returns the token after pending responses', () async {
      var tokenCalls = 0;
      final client = MockClient((request) async {
        tokenCalls++;
        expect(request.url.toString(), 'https://id.twitch.tv/oauth2/token');
        expect(request.bodyFields['client_id'], kTwitchClientId);
        expect(request.bodyFields['device_code'], 'dev-code-123');
        expect(request.bodyFields['grant_type'],
            'urn:ietf:params:oauth:grant-type:device_code');
        if (tokenCalls < 3) {
          return http.Response(
            json.encode({'message': 'authorization_pending'}),
            400,
          );
        }
        return http.Response(
          json.encode({
            'access_token': 'access-1',
            'refresh_token': 'refresh-1',
            'expires_in': 14400,
            'scope': ['user:read:chat'],
            'token_type': 'bearer',
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
      expect(tokenCalls, 3);
    });

    test('slow_down keeps polling instead of failing', () async {
      var tokenCalls = 0;
      final client = MockClient((request) async {
        tokenCalls++;
        if (tokenCalls == 1) {
          return http.Response(json.encode({'message': 'slow_down'}), 400);
        }
        return http.Response(
          json.encode({
            'access_token': 'access-2',
            'refresh_token': 'refresh-2',
            'expires_in': 14400,
            'scope': ['user:read:chat'],
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
      final client = MockClient((request) async =>
          http.Response(json.encode({'message': 'access_denied'}), 400));

      expect(
        serviceWith(client).pollForToken(
          kTestDeviceCode,
          onPending: () {},
          isCancelled: () => false,
        ),
        throwsA(isA<TwitchAuthException>()),
      );
    });

    test('expired_token throws', () {
      final client = MockClient((request) async =>
          http.Response(json.encode({'message': 'expired_token'}), 400));

      expect(
        serviceWith(client).pollForToken(
          kTestDeviceCode,
          onPending: () {},
          isCancelled: () => false,
        ),
        throwsA(isA<TwitchAuthException>()),
      );
    });

    test('cancellation aborts polling', () {
      final client = MockClient((request) async => http.Response(
          json.encode({'message': 'authorization_pending'}), 400));

      expect(
        serviceWith(client).pollForToken(
          kTestDeviceCode,
          onPending: () {},
          isCancelled: () => true,
        ),
        throwsA(isA<TwitchAuthException>()),
      );
    });
  });

  group('refreshToken', () {
    test('parses the refreshed token pair without a client secret', () async {
      final client = MockClient((request) async {
        expect(request.bodyFields['grant_type'], 'refresh_token');
        expect(request.bodyFields['refresh_token'], 'old-refresh');
        expect(request.bodyFields['client_id'], kTwitchClientId);
        expect(request.bodyFields.containsKey('client_secret'), isFalse);
        return http.Response(
          json.encode({
            'access_token': 'access-new',
            'refresh_token': 'refresh-new',
            'expires_in': 14400,
            'scope': ['user:read:chat'],
          }),
          200,
        );
      });

      final token = await serviceWith(client).refreshToken('old-refresh');

      expect(token.accessToken, 'access-new');
      expect(token.refreshToken, 'refresh-new');
    });

    test('throws on 400 (revoked/expired refresh token)', () {
      final client = MockClient((request) async => http.Response(
          json.encode({'message': 'Invalid refresh token'}), 400));

      expect(
        serviceWith(client).refreshToken('old-refresh'),
        throwsA(isA<TwitchAuthException>()),
      );
    });
  });

  group('validate', () {
    test('true on 200, sends the OAuth (not Bearer) prefix', () async {
      String? seenAuth;
      final client = MockClient((request) async {
        seenAuth = request.headers['Authorization'];
        return http.Response(json.encode({'login': 'kounex'}), 200);
      });

      final valid = await serviceWith(client).validate('access-1');

      expect(valid, isTrue);
      expect(seenAuth, 'OAuth access-1');
    });

    test('false on 401', () async {
      final client =
          MockClient((request) async => http.Response('{}', 401));

      expect(await serviceWith(client).validate('access-1'), isFalse);
    });

    test('throws on other statuses (e.g. 500 during a Twitch incident)', () {
      final client =
          MockClient((request) async => http.Response('oops', 500));

      expect(
        serviceWith(client).validate('access-1'),
        throwsA(isA<TwitchAuthException>().having(
          (e) => e.message,
          'message',
          'Token validation failed (status 500)',
        )),
      );
    });
  });

  group('fetchOwnUser', () {
    test('parses data[0] of the helix users response', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), 'https://api.twitch.tv/helix/users');
        expect(request.headers['Authorization'], 'Bearer access-1');
        expect(request.headers['Client-Id'], kTwitchClientId);
        return http.Response(
          json.encode({
            'data': [
              {
                'id': '1234',
                'login': 'kounex',
                'display_name': 'Kounex',
                'profile_image_url': 'https://example.com/p.png',
              }
            ],
          }),
          200,
        );
      });

      final user = await serviceWith(client).fetchOwnUser('access-1');

      expect(user.id, '1234');
      expect(user.login, 'kounex');
      expect(user.displayName, 'Kounex');
    });

    test('throws when data is empty', () {
      final client = MockClient(
          (request) async => http.Response(json.encode({'data': []}), 200));

      expect(
        serviceWith(client).fetchOwnUser('access-1'),
        throwsA(isA<TwitchAuthException>()),
      );
    });
  });

  group('revoke', () {
    test('posts client id + token and never throws', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), 'https://id.twitch.tv/oauth2/revoke');
        expect(request.bodyFields['client_id'], kTwitchClientId);
        expect(request.bodyFields['token'], 'access-1');
        return http.Response('', 200);
      });

      await serviceWith(client).revoke('access-1');
    });

    test('swallows network errors (best effort)', () async {
      final client = MockClient((request) async => throw Exception('down'));

      await serviceWith(client).revoke('access-1');
    });
  });
}
