import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/kick/kick_auth_service.dart';

void main() {
  KickAuthService serviceWith(MockClient client) =>
      KickAuthService(client: client);

  group('beginSession (PKCE)', () {
    test('verifier/challenge/state have the RFC 7636 S256 shape', () {
      final session = KickAuthService().beginSession();

      /// 64 random bytes → 86 base64url chars (no padding).
      expect(session.verifier.length, 86);
      expect(session.verifier, matches(RegExp(r'^[A-Za-z0-9\-_]+$')));
      expect(session.state.length, 43);
      expect(session.state, matches(RegExp(r'^[A-Za-z0-9\-_]+$')));

      final expectedChallenge = base64Url
          .encode(sha256.convert(ascii.encode(session.verifier)).bytes)
          .replaceAll('=', '');
      expect(session.codeChallenge, expectedChallenge);
      expect(session.codeChallenge, isNot(contains('=')));
    });

    test('sessions are unique', () {
      final service = KickAuthService();
      final a = service.beginSession();
      final b = service.beginSession();
      expect(a.verifier, isNot(b.verifier));
      expect(a.state, isNot(b.state));
    });
  });

  group('authorizeUrl', () {
    test('carries the full OAuth/PKCE parameter set', () {
      const session = KickPkceSession(
        verifier: 'v',
        state: 'state-1',
        codeChallenge: 'challenge-1',
      );

      final uri = KickAuthService().authorizeUrl(session);

      expect(uri.scheme, 'https');
      expect(uri.host, 'id.kick.com');
      expect(uri.path, '/oauth/authorize');
      expect(uri.queryParameters['response_type'], 'code');
      expect(uri.queryParameters['client_id'], kKickOAuthClientId);
      expect(uri.queryParameters['redirect_uri'], kKickOAuthRedirectUri);
      expect(uri.queryParameters['state'], 'state-1');
      expect(
        uri.queryParameters['scope'],
        'user:read chat:write moderation:ban moderation:chat_message:manage',
      );
      expect(uri.queryParameters['code_challenge'], 'challenge-1');
      expect(uri.queryParameters['code_challenge_method'], 'S256');
    });
  });

  group('parseRedirectCode', () {
    const session = KickPkceSession(
      verifier: 'v',
      state: 'state-1',
      codeChallenge: 'c',
    );

    test('extracts the code on a state match', () {
      final code = KickAuthService().parseRedirectCode(
        '$kKickOAuthRedirectUri?code=code-123&state=state-1',
        expectedState: session.state,
      );
      expect(code, 'code-123');
    });

    test('rejects a state mismatch', () {
      expect(
        () => KickAuthService().parseRedirectCode(
          '$kKickOAuthRedirectUri?code=code-123&state=other',
          expectedState: session.state,
        ),
        throwsA(isA<KickAuthException>()),
      );
    });

    test('rejects an OAuth denial', () {
      expect(
        () => KickAuthService().parseRedirectCode(
          '$kKickOAuthRedirectUri?error=access_denied&state=state-1',
          expectedState: session.state,
        ),
        throwsA(isA<KickAuthException>()),
      );
    });

    test('rejects a URL without a code', () {
      expect(
        () => KickAuthService().parseRedirectCode(
          '$kKickOAuthRedirectUri?state=state-1',
          expectedState: session.state,
        ),
        throwsA(isA<KickAuthException>()),
      );
    });

    test('rejects garbage', () {
      expect(
        () => KickAuthService().parseRedirectCode(
          'not a url at all',
          expectedState: session.state,
        ),
        throwsA(isA<KickAuthException>()),
      );
    });
  });

  group('exchangeCode', () {
    const session = KickPkceSession(
      verifier: 'verifier-1',
      state: 'state-1',
      codeChallenge: 'c',
    );

    test('posts the authorization_code exchange and parses the token', () async {
      final client = MockClient((request) async {
        expect(
          request.url.toString(),
          kKickOAuthClientId.isNotEmpty && kKickOAuthClientSecret.isEmpty
              ? kKickTokenProxyUrl
              : 'https://id.kick.com/oauth/token',
        );
        expect(request.bodyFields['grant_type'], 'authorization_code');
        expect(request.bodyFields['code'], 'code-123');
        expect(request.bodyFields['client_id'], kKickOAuthClientId);
        expect(request.bodyFields.containsKey('client_secret'), isFalse);
        expect(request.bodyFields['redirect_uri'], kKickOAuthRedirectUri);
        expect(request.bodyFields['code_verifier'], 'verifier-1');
        return http.Response(
          json.encode({
            'access_token': 'access-1',
            'refresh_token': 'refresh-1',
            'expires_in': 3600,
            'scope':
                'user:read chat:write moderation:ban moderation:chat_message:manage',
            'token_type': 'Bearer',
          }),
          200,
        );
      });

      final token = await serviceWith(
        client,
      ).exchangeCode(code: 'code-123', session: session);

      expect(token.accessToken, 'access-1');
      expect(token.refreshToken, 'refresh-1');
      expect(token.scope, kKickChatScopes);
      expect(token.tokenType, 'Bearer');
    });

    test('throws a typed error on non-200', () {
      final client = MockClient(
        (request) async =>
            http.Response(json.encode({'error': 'invalid_grant'}), 400),
      );

      expect(
        serviceWith(client).exchangeCode(code: 'dead', session: session),
        throwsA(
          isA<KickAuthException>().having(
            (e) => e.statusCode,
            'statusCode',
            400,
          ),
        ),
      );
    });
  });

  group('refreshToken', () {
    test('posts the refresh and parses the rotated pair', () async {
      final client = MockClient((request) async {
        expect(request.bodyFields['grant_type'], 'refresh_token');
        expect(request.bodyFields['refresh_token'], 'old-refresh');
        expect(request.bodyFields['client_id'], kKickOAuthClientId);
        return http.Response(
          json.encode({
            'access_token': 'access-new',
            'refresh_token': 'refresh-new',
            'expires_in': 3600,
            'scope': 'user:read chat:write',
          }),
          200,
        );
      });

      final token = await serviceWith(client).refreshToken('old-refresh');

      /// Kick rotates BOTH tokens on refresh.
      expect(token.accessToken, 'access-new');
      expect(token.refreshToken, 'refresh-new');
    });

    test('single-flight: concurrent refreshes share one HTTP call', () async {
      var calls = 0;
      final gate = Completer<void>();
      final client = MockClient((request) async {
        calls++;
        await gate.future;
        return http.Response(
          json.encode({
            'access_token': 'access-new',
            'refresh_token': 'refresh-new',
            'expires_in': 3600,
          }),
          200,
        );
      });
      final service = serviceWith(client);

      final first = service.refreshToken('old-refresh');
      final second = service.refreshToken('old-refresh');
      gate.complete();
      final results = await Future.wait([first, second]);

      expect(calls, 1);
      expect(results[0].accessToken, 'access-new');
      expect(results[1].accessToken, 'access-new');

      /// A refresh after the in-flight one completed hits HTTP again.
      await service.refreshToken('refresh-new');
      expect(calls, 2);
    });

    test('a failed refresh releases the single-flight slot', () async {
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        if (calls == 1) return http.Response('nope', 400);
        return http.Response(
          json.encode({
            'access_token': 'access-new',
            'refresh_token': 'refresh-new',
            'expires_in': 3600,
          }),
          200,
        );
      });
      final service = serviceWith(client);

      await expectLater(
        service.refreshToken('old-refresh'),
        throwsA(isA<KickAuthException>()),
      );
      final token = await service.refreshToken('old-refresh');
      expect(token.accessToken, 'access-new');
      expect(calls, 2);
    });
  });

  group('fetchOwnUser', () {
    test('parses the first user entry', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), 'https://api.kick.com/public/v1/users');
        expect(request.headers['Authorization'], 'Bearer access-1');
        return http.Response(
          json.encode({
            'data': [
              {
                'user_id': 4242,
                'name': 'Kicker',
                'profile_picture': 'https://pic.example/k.png',
              },
            ],
          }),
          200,
        );
      });

      final identity = await serviceWith(client).fetchOwnUser('access-1');

      expect(identity?.userId, 4242);
      expect(identity?.name, 'Kicker');
      expect(identity?.profilePicture, 'https://pic.example/k.png');
    });

    test('returns null on an empty data list', () async {
      final client = MockClient(
        (request) async => http.Response(json.encode({'data': []}), 200),
      );

      expect(await serviceWith(client).fetchOwnUser('access-1'), isNull);
    });

    test('throws on non-200', () {
      final client = MockClient((request) async => http.Response('nope', 401));

      expect(
        serviceWith(client).fetchOwnUser('dead'),
        throwsA(isA<KickAuthException>()),
      );
    });
  });

  group('revoke', () {
    test('posts token + hint as query parameters and never throws', () async {
      final client = MockClient((request) async {
        expect(
          request.url.toString(),
          'https://id.kick.com/oauth/revoke?token=access-1&token_hint_type=access_token',
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

  group('client credential resolution', () {
    test('falls back to the constants when the settings box is not open', () {
      expect(
        serviceWith(
          MockClient((request) async => http.Response('', 200)),
        ).resolveClientId(),
        kKickOAuthClientId,
      );
    });

    test('BYO client id + secret are sent on exchange and refresh', () async {
      final tempDir = await Directory.systemTemp.createTemp('kick_auth_byo');
      Hive.init(tempDir.path);
      try {
        final settings = await Hive.openBox(HiveKeys.Settings.name);
        await settings.put(SettingsKeys.KickOAuthClientId.name, 'client-1');
        await settings.put(SettingsKeys.KickOAuthClientSecret.name, 'secret-1');

        final appOwned =
            kKickOAuthClientId.isNotEmpty && kKickOAuthClientSecret.isEmpty;
        var calls = 0;
        final client = MockClient((request) async {
          calls++;
          if (appOwned) {
            expect(request.url.toString(), kKickTokenProxyUrl);
            expect(request.bodyFields['client_id'], kKickOAuthClientId);
            expect(request.bodyFields.containsKey('client_secret'), isFalse);
          } else {
            expect(request.bodyFields['client_id'], 'client-1');
            expect(request.bodyFields['client_secret'], 'secret-1');
          }
          return http.Response(
            json.encode({
              'access_token': 'access-1',
              'refresh_token': 'refresh-1',
              'expires_in': 3600,
            }),
            200,
          );
        });
        final service = serviceWith(client);

        await service.exchangeCode(
          code: 'code-1',
          session: const KickPkceSession(
            verifier: 'v',
            state: 's',
            codeChallenge: 'c',
          ),
        );
        await service.refreshToken('refresh-1');

        expect(calls, 2);
      } finally {
        await Hive.close();
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      }
    });
  });
}
