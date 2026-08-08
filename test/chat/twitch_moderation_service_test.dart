import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';
import 'package:obs_blade/utils/twitch/twitch_moderation_service.dart';

void main() {
  group('deleteChatMessage', () {
    test('DELETEs moderation/chat with broadcaster/moderator/message params',
        () async {
      final client = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(
          request.url.toString(),
          'https://api.twitch.tv/helix/moderation/chat'
          '?broadcaster_id=chan-1&moderator_id=user-1&message_id=msg-1',
        );
        expect(request.headers['Authorization'], 'Bearer token-1');
        expect(request.headers['Client-Id'], kTwitchClientId);
        return http.Response('', 204);
      });

      await TwitchModerationService(client: client).deleteChatMessage(
        accessToken: 'token-1',
        broadcasterId: 'chan-1',
        moderatorId: 'user-1',
        messageId: 'msg-1',
      );
    });

    test('throws TwitchAuthException with status on non-204', () {
      final client = MockClient((request) async => http.Response('nope', 403));

      expect(
        TwitchModerationService(client: client).deleteChatMessage(
          accessToken: 'token-1',
          broadcasterId: 'chan-1',
          moderatorId: 'user-1',
          messageId: 'msg-1',
        ),
        throwsA(
          isA<TwitchAuthException>()
              .having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });
  });

  group('banUser', () {
    test('POSTs moderation/bans with a duration for a timeout', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://api.twitch.tv/helix/moderation/bans'
          '?broadcaster_id=chan-1&moderator_id=user-1',
        );
        expect(request.headers['Authorization'], 'Bearer token-1');
        expect(request.headers['Client-Id'], kTwitchClientId);
        expect(request.headers['Content-Type'], 'application/json');
        expect(json.decode(request.body), {
          'data': {'user_id': 'bad-1', 'duration': 600},
        });
        return http.Response(json.encode({'data': []}), 200);
      });

      await TwitchModerationService(client: client).banUser(
        accessToken: 'token-1',
        broadcasterId: 'chan-1',
        moderatorId: 'user-1',
        userId: 'bad-1',
        durationSeconds: 600,
      );
    });

    test('omits the duration key for a permanent ban', () async {
      final client = MockClient((request) async {
        final body = json.decode(request.body) as Map<String, dynamic>;
        expect(body, {
          'data': {'user_id': 'bad-1'},
        });
        expect(
            (body['data'] as Map<String, dynamic>).containsKey('duration'),
            isFalse);
        return http.Response(json.encode({'data': []}), 200);
      });

      await TwitchModerationService(client: client).banUser(
        accessToken: 'token-1',
        broadcasterId: 'chan-1',
        moderatorId: 'user-1',
        userId: 'bad-1',
      );
    });

    test('throws TwitchAuthException with status on non-200', () {
      final client = MockClient((request) async => http.Response('nope', 401));

      expect(
        TwitchModerationService(client: client).banUser(
          accessToken: 'token-1',
          broadcasterId: 'chan-1',
          moderatorId: 'user-1',
          userId: 'bad-1',
        ),
        throwsA(
          isA<TwitchAuthException>()
              .having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });
  });
}
