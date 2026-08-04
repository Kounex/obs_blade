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
        expect(request.bodyFields['scopes'], 'user:read:chat');
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
}
