import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/types/classes/twitch/chat_settings.dart';
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

  group('clearChat', () {
    test('DELETEs moderation/chat without message_id', () async {
      final client = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(
          request.url.toString(),
          'https://api.twitch.tv/helix/moderation/chat'
          '?broadcaster_id=chan-1&moderator_id=user-1',
        );
        expect(request.url.queryParameters.containsKey('message_id'), isFalse);
        expect(request.headers['Authorization'], 'Bearer token-1');
        expect(request.headers['Client-Id'], kTwitchClientId);
        return http.Response('', 204);
      });

      await TwitchModerationService(client: client).clearChat(
        accessToken: 'token-1',
        broadcasterId: 'chan-1',
        moderatorId: 'user-1',
      );
    });

    test('throws TwitchAuthException with status on non-204', () {
      final client = MockClient((request) async => http.Response('nope', 403));

      expect(
        TwitchModerationService(client: client).clearChat(
          accessToken: 'token-1',
          broadcasterId: 'chan-1',
          moderatorId: 'user-1',
        ),
        throwsA(
          isA<TwitchAuthException>()
              .having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });
  });

  group('getChatSettings', () {
    test('GETs chat/settings and parses mode fields', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.toString(),
          'https://api.twitch.tv/helix/chat/settings'
          '?broadcaster_id=chan-1&moderator_id=user-1',
        );
        expect(request.headers['Authorization'], 'Bearer token-1');
        expect(request.headers['Client-Id'], kTwitchClientId);
        return http.Response(
          json.encode({
            'data': [
              {
                'broadcaster_id': 'chan-1',
                'moderator_id': 'user-1',
                'emote_mode': true,
                'follower_mode': true,
                'follower_mode_duration': 30,
                'subscriber_mode': false,
                'slow_mode': true,
                'slow_mode_wait_time': 10,
                'unique_chat_mode': false,
              },
            ],
          }),
          200,
        );
      });

      final settings =
          await TwitchModerationService(client: client).getChatSettings(
        accessToken: 'token-1',
        broadcasterId: 'chan-1',
        moderatorId: 'user-1',
      );

      expect(settings, isA<TwitchChatSettings>());
      expect(settings.emoteMode, isTrue);
      expect(settings.followerMode, isTrue);
      expect(settings.followerModeDurationMinutes, 30);
      expect(settings.subscriberMode, isFalse);
      expect(settings.slowMode, isTrue);
      expect(settings.slowModeWaitTimeSeconds, 10);
      expect(settings.uniqueChatMode, isFalse);
    });
  });

  group('updateChatSettings', () {
    test('PATCHes only the fields passed', () async {
      final client = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(
          request.url.toString(),
          'https://api.twitch.tv/helix/chat/settings'
          '?broadcaster_id=chan-1&moderator_id=user-1',
        );
        expect(request.headers['Authorization'], 'Bearer token-1');
        expect(request.headers['Client-Id'], kTwitchClientId);
        expect(request.headers['Content-Type'], 'application/json');
        expect(json.decode(request.body), {
          'emote_mode': true,
          'slow_mode': true,
          'slow_mode_wait_time': 30,
        });
        return http.Response('', 204);
      });

      await TwitchModerationService(client: client).updateChatSettings(
        accessToken: 'token-1',
        broadcasterId: 'chan-1',
        moderatorId: 'user-1',
        emoteMode: true,
        slowMode: true,
        slowModeWaitTimeSeconds: 30,
      );
    });
  });

  group('getShieldModeStatus', () {
    test('GETs moderation/shield_mode and parses is_active', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.toString(),
          'https://api.twitch.tv/helix/moderation/shield_mode'
          '?broadcaster_id=chan-1&moderator_id=user-1',
        );
        expect(request.headers['Authorization'], 'Bearer token-1');
        expect(request.headers['Client-Id'], kTwitchClientId);
        return http.Response(
          json.encode({
            'data': [
              {
                'is_active': true,
                'broadcaster_id': 'chan-1',
                'moderator_id': 'user-1',
              },
            ],
          }),
          200,
        );
      });

      final isActive =
          await TwitchModerationService(client: client).getShieldModeStatus(
        accessToken: 'token-1',
        broadcasterId: 'chan-1',
        moderatorId: 'user-1',
      );

      expect(isActive, isTrue);
    });
  });

  group('updateShieldModeStatus', () {
    test('PUTs moderation/shield_mode with is_active', () async {
      final client = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(
          request.url.toString(),
          'https://api.twitch.tv/helix/moderation/shield_mode'
          '?broadcaster_id=chan-1&moderator_id=user-1',
        );
        expect(request.headers['Authorization'], 'Bearer token-1');
        expect(request.headers['Client-Id'], kTwitchClientId);
        expect(request.headers['Content-Type'], 'application/json');
        expect(json.decode(request.body), {'is_active': false});
        return http.Response(
          json.encode({
            'data': [
              {
                'is_active': false,
                'broadcaster_id': 'chan-1',
                'moderator_id': 'user-1',
              },
            ],
          }),
          200,
        );
      });

      await TwitchModerationService(client: client).updateShieldModeStatus(
        accessToken: 'token-1',
        broadcasterId: 'chan-1',
        moderatorId: 'user-1',
        isActive: false,
      );
    });
  });

  group('sendChatAnnouncement', () {
    test('POSTs chat/announcements with message and color', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://api.twitch.tv/helix/chat/announcements'
          '?broadcaster_id=chan-1&moderator_id=user-1',
        );
        expect(request.headers['Authorization'], 'Bearer token-1');
        expect(request.headers['Client-Id'], kTwitchClientId);
        expect(request.headers['Content-Type'], 'application/json');
        expect(json.decode(request.body), {
          'message': 'Hello chat!',
          'color': 'primary',
        });
        return http.Response('', 204);
      });

      await TwitchModerationService(client: client).sendChatAnnouncement(
        accessToken: 'token-1',
        broadcasterId: 'chan-1',
        moderatorId: 'user-1',
        message: 'Hello chat!',
        color: 'primary',
      );
    });
  });
}
