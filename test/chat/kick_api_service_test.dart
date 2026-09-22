import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/utils/kick/kick_api_service.dart';
import 'package:obs_blade/utils/kick/kick_channel_service.dart';

/// Records the forceRefresh sequence the API service asked for.
class _TokenProvider {
  final List<bool> calls = <bool>[];
  String token = 'token-1';
  String refreshedToken = 'token-2';

  Future<String> call({required bool forceRefresh}) async {
    this.calls.add(forceRefresh);
    return forceRefresh ? this.refreshedToken : this.token;
  }
}

void main() {
  const broadcasterUserId = 4242;

  group('sendMessage', () {
    test('posts the user message and returns the message id', () async {
      final provider = _TokenProvider();
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), 'https://api.kick.com/public/v1/chat');
        expect(request.headers['Authorization'], 'Bearer token-1');
        expect(request.headers['Content-Type'], 'application/json');
        final body = json.decode(request.body) as Map<String, Object?>;
        expect(body['type'], 'user');
        expect(body['broadcaster_user_id'], broadcasterUserId);
        expect(body['content'], 'hello kick');
        expect(body.containsKey('reply_to_message_id'), isFalse);
        return http.Response(
          json.encode({
            'data': {'is_sent': true, 'message_id': 'msg-1'},
          }),
          200,
        );
      });

      final id =
          await KickApiService(
            client: client,
            tokenProvider: provider.call,
          ).sendMessage(
            broadcasterUserId: broadcasterUserId,
            content: 'hello kick',
          );

      expect(id, 'msg-1');
    });

    test('forwards reply_to_message_id when set', () async {
      final client = MockClient((request) async {
        final body = json.decode(request.body) as Map<String, Object?>;
        expect(body['reply_to_message_id'], 'parent-1');
        return http.Response(
          json.encode({
            'data': {'is_sent': true, 'message_id': 'msg-2'},
          }),
          200,
        );
      });

      await KickApiService(
        client: client,
        tokenProvider: _TokenProvider().call,
      ).sendMessage(
        broadcasterUserId: broadcasterUserId,
        content: 'reply',
        replyToMessageId: 'parent-1',
      );
    });

    test('throws when Kick reports is_sent false', () {
      final client = MockClient(
        (request) async => http.Response(
          json.encode({
            'data': {'is_sent': false},
          }),
          200,
        ),
      );

      expect(
        KickApiService(
          client: client,
          tokenProvider: _TokenProvider().call,
        ).sendMessage(broadcasterUserId: broadcasterUserId, content: 'x'),
        throwsA(isA<KickApiException>()),
      );
    });

    test('403 surfaces as a typed permission error', () {
      final client = MockClient((request) async => http.Response('{}', 403));

      expect(
        KickApiService(
          client: client,
          tokenProvider: _TokenProvider().call,
        ).sendMessage(broadcasterUserId: broadcasterUserId, content: 'x'),
        throwsA(
          isA<KickApiException>()
              .having((e) => e.statusCode, 'statusCode', 403)
              .having((e) => e.message, 'message', contains('no permission')),
        ),
      );
    });

    test('429 surfaces as a typed rate-limit error', () {
      final client = MockClient((request) async => http.Response('{}', 429));

      expect(
        KickApiService(
          client: client,
          tokenProvider: _TokenProvider().call,
        ).sendMessage(broadcasterUserId: broadcasterUserId, content: 'x'),
        throwsA(
          isA<KickApiException>()
              .having((e) => e.statusCode, 'statusCode', 429)
              .having((e) => e.message, 'message', contains('rate limit')),
        ),
      );
    });
  });

  group('401 handling', () {
    test('refreshes once and retries once with the new token', () async {
      final provider = _TokenProvider();
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        if (calls == 1) {
          expect(request.headers['Authorization'], 'Bearer token-1');
          return http.Response('{}', 401);
        }
        expect(request.headers['Authorization'], 'Bearer token-2');
        return http.Response(
          json.encode({
            'data': {'is_sent': true, 'message_id': 'msg-1'},
          }),
          200,
        );
      });

      final id = await KickApiService(
        client: client,
        tokenProvider: provider.call,
      ).sendMessage(broadcasterUserId: broadcasterUserId, content: 'x');

      expect(id, 'msg-1');
      expect(calls, 2);
      expect(provider.calls, [false, true]);
    });

    test('a second 401 surfaces instead of retrying again', () async {
      final provider = _TokenProvider();
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        return http.Response('{}', 401);
      });

      await expectLater(
        KickApiService(
          client: client,
          tokenProvider: provider.call,
        ).sendMessage(broadcasterUserId: broadcasterUserId, content: 'x'),
        throwsA(
          isA<KickApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            401,
          ),
        ),
      );
      expect(calls, 2);
      expect(provider.calls, [false, true]);
    });
  });

  group('deleteMessage', () {
    test('DELETEs the message (204)', () async {
      final client = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(
          request.url.toString(),
          'https://api.kick.com/public/v1/chat/msg-1',
        );
        expect(request.headers['Authorization'], 'Bearer token-1');
        return http.Response('', 204);
      });

      await KickApiService(
        client: client,
        tokenProvider: _TokenProvider().call,
      ).deleteMessage(messageId: 'msg-1');
    });

    test('403 = not a mod surfaces typed', () {
      final client = MockClient((request) async => http.Response('{}', 403));

      expect(
        KickApiService(
          client: client,
          tokenProvider: _TokenProvider().call,
        ).deleteMessage(messageId: 'msg-1'),
        throwsA(
          isA<KickApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            403,
          ),
        ),
      );
    });
  });

  group('banUser', () {
    test('posts a permanent ban (no duration)', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://api.kick.com/public/v1/moderation/bans',
        );
        final body = json.decode(request.body) as Map<String, Object?>;
        expect(body['broadcaster_user_id'], broadcasterUserId);
        expect(body['user_id'], 77);
        expect(body.containsKey('duration'), isFalse);
        expect(body.containsKey('reason'), isFalse);
        return http.Response('', 200);
      });

      await KickApiService(
        client: client,
        tokenProvider: _TokenProvider().call,
      ).banUser(broadcasterUserId: broadcasterUserId, userId: 77);
    });

    test('posts a timeout with duration in minutes + reason', () async {
      final client = MockClient((request) async {
        final body = json.decode(request.body) as Map<String, Object?>;
        expect(body['duration'], 10);
        expect(body['reason'], 'spam');
        return http.Response('', 200);
      });

      await KickApiService(
        client: client,
        tokenProvider: _TokenProvider().call,
      ).banUser(
        broadcasterUserId: broadcasterUserId,
        userId: 77,
        durationMinutes: 10,
        reason: 'spam',
      );
    });
  });

  group('fetchUser', () {
    test('GETs the user and maps the profile', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.toString(),
          'https://api.kick.com/public/v1/users?id=77',
        );
        expect(request.headers['Authorization'], 'Bearer token-1');
        return http.Response(
          json.encode({
            'data': [
              {
                'user_id': 77,
                'name': 'chatterly',
                'email': 'chatterly@example.com',
                'profile_picture': 'https://example.com/avatar.png',
              },
            ],
          }),
          200,
        );
      });

      final identity = await KickApiService(
        client: client,
        tokenProvider: _TokenProvider().call,
      ).fetchUser(77);

      expect(identity, isNotNull);
      expect(identity!.userId, 77);
      expect(identity.name, 'chatterly');
      expect(identity.profilePicture, 'https://example.com/avatar.png');
    });

    test('returns null when the data array is empty', () async {
      final client = MockClient(
        (request) async => http.Response(json.encode({'data': []}), 200),
      );

      final identity = await KickApiService(
        client: client,
        tokenProvider: _TokenProvider().call,
      ).fetchUser(77);

      expect(identity, isNull);
    });

    test('401 refreshes once and retries once', () async {
      final provider = _TokenProvider();
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        if (calls == 1) return http.Response('{}', 401);
        return http.Response(
          json.encode({
            'data': [
              {'user_id': 77, 'name': 'chatterly', 'profile_picture': null},
            ],
          }),
          200,
        );
      });

      final identity = await KickApiService(
        client: client,
        tokenProvider: provider.call,
      ).fetchUser(77);

      expect(identity!.userId, 77);
      expect(calls, 2);
      expect(provider.calls, [false, true]);
    });

    test('non-200 surfaces as a typed error', () {
      final client = MockClient((request) async => http.Response('{}', 403));

      expect(
        KickApiService(
          client: client,
          tokenProvider: _TokenProvider().call,
        ).fetchUser(77),
        throwsA(
          isA<KickApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            403,
          ),
        ),
      );
    });
  });

  group('unbanUser', () {
    test('DELETEs with a JSON body', () async {
      final client = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(
          request.url.toString(),
          'https://api.kick.com/public/v1/moderation/bans',
        );
        final body = json.decode(request.body) as Map<String, Object?>;
        expect(body['broadcaster_user_id'], broadcasterUserId);
        expect(body['user_id'], 77);
        return http.Response('', 204);
      });

      await KickApiService(
        client: client,
        tokenProvider: _TokenProvider().call,
      ).unbanUser(broadcasterUserId: broadcasterUserId, userId: 77);
    });
  });
}
