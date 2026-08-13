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

  group('getPinnedChatMessage', () {
    test('GETs chat/pins and parses the pinned message', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.toString(),
          'https://api.twitch.tv/helix/chat/pins'
          '?broadcaster_id=chan-1&moderator_id=user-1',
        );
        expect(request.headers['Authorization'], 'Bearer token-1');
        expect(request.headers['Client-Id'], kTwitchClientId);
        return http.Response(
          json.encode({
            'data': [
              {
                'message_id': 'abc-def-123-456',
                'broadcaster_id': 'chan-1',
                'sender_user_id': 'user-2',
                'sender_user_login': 'chatter',
                'sender_user_name': 'Chatter',
                'pinned_by_user_id': 'user-1',
                'pinned_by_user_login': 'kounex',
                'pinned_by_user_name': 'Kounex',
                'message': {
                  'text': 'remember the giveaway Kappa',
                  'fragments': [
                    {'type': 'text', 'text': 'remember the giveaway '},
                    {
                      'type': 'emote',
                      'text': 'Kappa',
                      'emote': {'id': '25', 'emote_set_id': '0'},
                    },
                  ],
                },
                'starts_at': '2026-08-13T10:00:00Z',
                'ends_at': '2026-08-13T10:15:00Z',
                'updated_at': '2026-08-13T10:00:00Z',
              },
            ],
          }),
          200,
        );
      });

      final pinned =
          await TwitchModerationService(client: client).getPinnedChatMessage(
        accessToken: 'token-1',
        broadcasterId: 'chan-1',
        moderatorId: 'user-1',
      );

      expect(pinned, isNotNull);
      expect(pinned!.messageId, 'abc-def-123-456');
      expect(pinned.senderUserName, 'Chatter');
      expect(pinned.pinnedByUserLogin, 'kounex');
      expect(pinned.message.text, 'remember the giveaway Kappa');
      expect(pinned.message.fragments, hasLength(2));
      expect(pinned.endsAt, isNotNull);
      expect(pinned.startsAt, DateTime.utc(2026, 8, 13, 10));
    });

    test('null ends_at parses as pinned-until-stream-end', () async {
      final client = MockClient((request) async => http.Response(
            json.encode({
              'data': [
                {
                  'message_id': 'm1',
                  'broadcaster_id': 'chan-1',
                  'sender_user_id': 'user-2',
                  'sender_user_login': 'chatter',
                  'sender_user_name': 'Chatter',
                  'pinned_by_user_id': 'user-1',
                  'pinned_by_user_login': 'kounex',
                  'pinned_by_user_name': 'Kounex',
                  'message': {'text': 'hi', 'fragments': []},
                  'starts_at': '2026-08-13T10:00:00Z',
                  'ends_at': null,
                  'updated_at': '2026-08-13T10:00:00Z',
                },
              ],
            }),
            200,
          ));

      final pinned =
          await TwitchModerationService(client: client).getPinnedChatMessage(
        accessToken: 'token-1',
        broadcasterId: 'chan-1',
        moderatorId: 'user-1',
      );

      expect(pinned, isNotNull);
      expect(pinned!.endsAt, isNull);
      expect(pinned.message.fragments, isEmpty);
    });

    test('empty data means nothing is pinned (null, not an error)', () async {
      final client = MockClient((request) async => http.Response(
            json.encode({'data': []}),
            200,
          ));

      final pinned =
          await TwitchModerationService(client: client).getPinnedChatMessage(
        accessToken: 'token-1',
        broadcasterId: 'chan-1',
        moderatorId: 'user-1',
      );

      expect(pinned, isNull);
    });

    test('throws TwitchAuthException with status on non-200', () {
      final client = MockClient((request) async => http.Response('nope', 401));

      expect(
        TwitchModerationService(client: client).getPinnedChatMessage(
          accessToken: 'token-1',
          broadcasterId: 'chan-1',
          moderatorId: 'user-1',
        ),
        throwsA(
          isA<TwitchAuthException>()
              .having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });
  });

  group('pinChatMessage', () {
    test('PUTs chat/pins with the message id and no duration', () async {
      final client = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(
          request.url.toString(),
          'https://api.twitch.tv/helix/chat/pins'
          '?broadcaster_id=chan-1&moderator_id=user-1&message_id=msg-1',
        );
        expect(request.url.queryParameters.containsKey('duration_seconds'),
            isFalse);
        expect(request.headers['Authorization'], 'Bearer token-1');
        expect(request.headers['Client-Id'], kTwitchClientId);
        return http.Response('', 204);
      });

      await TwitchModerationService(client: client).pinChatMessage(
        accessToken: 'token-1',
        broadcasterId: 'chan-1',
        moderatorId: 'user-1',
        messageId: 'msg-1',
      );
    });

    test('throws TwitchAuthException with status on non-204', () {
      final client = MockClient((request) async => http.Response('nope', 409));

      expect(
        TwitchModerationService(client: client).pinChatMessage(
          accessToken: 'token-1',
          broadcasterId: 'chan-1',
          moderatorId: 'user-1',
          messageId: 'msg-1',
        ),
        throwsA(
          isA<TwitchAuthException>()
              .having((e) => e.statusCode, 'statusCode', 409),
        ),
      );
    });
  });

  group('unpinChatMessage', () {
    test('DELETEs chat/pins with the message id', () async {
      final client = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(
          request.url.toString(),
          'https://api.twitch.tv/helix/chat/pins'
          '?broadcaster_id=chan-1&moderator_id=user-1&message_id=msg-1',
        );
        expect(request.headers['Authorization'], 'Bearer token-1');
        expect(request.headers['Client-Id'], kTwitchClientId);
        return http.Response('', 204);
      });

      await TwitchModerationService(client: client).unpinChatMessage(
        accessToken: 'token-1',
        broadcasterId: 'chan-1',
        moderatorId: 'user-1',
        messageId: 'msg-1',
      );
    });

    test('throws TwitchAuthException with status on non-204', () {
      final client = MockClient((request) async => http.Response('nope', 403));

      expect(
        TwitchModerationService(client: client).unpinChatMessage(
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

  group('getBannedUsers', () {
    test('GETs moderation/banned and parses bans and timeouts', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.toString(),
          'https://api.twitch.tv/helix/moderation/banned'
          '?broadcaster_id=chan-1&first=100',
        );
        expect(request.headers['Authorization'], 'Bearer token-1');
        expect(request.headers['Client-Id'], kTwitchClientId);
        return http.Response(
          json.encode({
            'data': [
              {
                'user_id': 'bad-1',
                'user_login': 'troll',
                'user_name': 'Troll',
                'created_at': '2026-08-01T10:00:00Z',
                'expires_at': '',
                'reason': 'spam',
                'moderator_id': 'user-1',
                'moderator_login': 'kounex',
                'moderator_name': 'Kounex',
              },
              {
                'user_id': 'bad-2',
                'user_login': 'capslock',
                'user_name': 'CapsLock',
                'created_at': '2026-08-02T10:00:00Z',
                'expires_at': '2026-08-20T10:00:00Z',
                'reason': 'shouting',
                'moderator_id': 'user-1',
                'moderator_login': 'kounex',
                'moderator_name': 'Kounex',
              },
            ],
            'pagination': {},
          }),
          200,
        );
      });

      final users = await TwitchModerationService(client: client)
          .getBannedUsers(accessToken: 'token-1', broadcasterId: 'chan-1');

      expect(users, hasLength(2));

      /// Empty-string expiry = permanent ban.
      expect(users[0].userId, 'bad-1');
      expect(users[0].expiresAt, isNull);
      expect(users[0].isTimeout, isFalse);
      expect(users[0].reason, 'spam');
      expect(users[0].moderatorName, 'Kounex');

      expect(users[1].expiresAt, DateTime.utc(2026, 8, 20, 10));
      expect(users[1].isTimeout, isTrue);
    });

    test('follows the pagination cursor', () async {
      final requestedAfters = <String?>[];
      final client = MockClient((request) async {
        requestedAfters.add(request.url.queryParameters['after']);
        if (request.url.queryParameters['after'] == null) {
          return http.Response(
            json.encode({
              'data': [
                {'user_id': 'bad-1', 'expires_at': ''},
              ],
              'pagination': {'cursor': 'page-2'},
            }),
            200,
          );
        }
        return http.Response(
          json.encode({
            'data': [
              {'user_id': 'bad-2', 'expires_at': ''},
            ],
            'pagination': {},
          }),
          200,
        );
      });

      final users = await TwitchModerationService(client: client)
          .getBannedUsers(accessToken: 'token-1', broadcasterId: 'chan-1');

      expect(requestedAfters, [null, 'page-2']);
      expect(users.map((user) => user.userId), ['bad-1', 'bad-2']);
    });

    test('throws TwitchAuthException with status on non-200', () {
      final client = MockClient((request) async => http.Response('nope', 401));

      expect(
        TwitchModerationService(client: client).getBannedUsers(
          accessToken: 'token-1',
          broadcasterId: 'chan-1',
        ),
        throwsA(
          isA<TwitchAuthException>()
              .having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });
  });

  group('unbanUser', () {
    test('DELETEs moderation/bans with the user id', () async {
      final client = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(
          request.url.toString(),
          'https://api.twitch.tv/helix/moderation/bans'
          '?broadcaster_id=chan-1&moderator_id=user-1&user_id=bad-1',
        );
        expect(request.headers['Authorization'], 'Bearer token-1');
        expect(request.headers['Client-Id'], kTwitchClientId);
        return http.Response('', 204);
      });

      await TwitchModerationService(client: client).unbanUser(
        accessToken: 'token-1',
        broadcasterId: 'chan-1',
        moderatorId: 'user-1',
        userId: 'bad-1',
      );
    });

    test('throws TwitchAuthException with status on non-204', () {
      final client = MockClient((request) async => http.Response('nope', 400));

      expect(
        TwitchModerationService(client: client).unbanUser(
          accessToken: 'token-1',
          broadcasterId: 'chan-1',
          moderatorId: 'user-1',
          userId: 'bad-1',
        ),
        throwsA(
          isA<TwitchAuthException>()
              .having((e) => e.statusCode, 'statusCode', 400),
        ),
      );
    });
  });

  group('getPendingUnbanRequests', () {
    test('GETs moderation/unban_requests with the required status param',
        () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.toString(),
          'https://api.twitch.tv/helix/moderation/unban_requests'
          '?broadcaster_id=chan-1&moderator_id=user-1&status=pending'
          '&first=100',
        );
        expect(request.headers['Authorization'], 'Bearer token-1');
        expect(request.headers['Client-Id'], kTwitchClientId);
        return http.Response(
          json.encode({
            'data': [
              {
                'id': 'req-1',
                'user_id': 'bad-1',
                'user_login': 'troll',
                'user_name': 'Troll',
                'text': 'sorry, will behave',
                'status': 'pending',
                'created_at': '2026-08-10T10:00:00Z',
                'resolved_at': null,
                'resolution_text': null,
                'moderator_id': null,
                'moderator_login': null,
                'moderator_name': null,
              },
            ],
            'pagination': {},
          }),
          200,
        );
      });

      final requests = await TwitchModerationService(client: client)
          .getPendingUnbanRequests(
        accessToken: 'token-1',
        broadcasterId: 'chan-1',
        moderatorId: 'user-1',
      );

      expect(requests, hasLength(1));
      expect(requests[0].id, 'req-1');
      expect(requests[0].userName, 'Troll');
      expect(requests[0].text, 'sorry, will behave');
      expect(requests[0].status, 'pending');
      expect(requests[0].createdAt, DateTime.utc(2026, 8, 10, 10));
      expect(requests[0].resolvedAt, isNull);
      expect(requests[0].resolutionText, isNull);
      expect(requests[0].moderatorId, isNull);
    });

    test('throws TwitchAuthException with status on non-200', () {
      final client = MockClient((request) async => http.Response('nope', 403));

      expect(
        TwitchModerationService(client: client).getPendingUnbanRequests(
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

  group('resolveUnbanRequest', () {
    test('PUTs moderation/unban_requests with the resolution status',
        () async {
      final client = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(
          request.url.toString(),
          'https://api.twitch.tv/helix/moderation/unban_requests'
          '?broadcaster_id=chan-1&moderator_id=user-1'
          '&unban_request_id=req-1',
        );
        expect(request.headers['Authorization'], 'Bearer token-1');
        expect(request.headers['Content-Type'], 'application/json');
        expect(json.decode(request.body), {'status': 'approved'});
        return http.Response(json.encode({'data': []}), 200);
      });

      await TwitchModerationService(client: client).resolveUnbanRequest(
        accessToken: 'token-1',
        broadcasterId: 'chan-1',
        moderatorId: 'user-1',
        requestId: 'req-1',
        approved: true,
      );
    });

    test('sends denied plus the resolution text', () async {
      final client = MockClient((request) async {
        expect(json.decode(request.body), {
          'status': 'denied',
          'resolution_text': 'ban stays',
        });
        return http.Response(json.encode({'data': []}), 200);
      });

      await TwitchModerationService(client: client).resolveUnbanRequest(
        accessToken: 'token-1',
        broadcasterId: 'chan-1',
        moderatorId: 'user-1',
        requestId: 'req-1',
        approved: false,
        resolutionText: 'ban stays',
      );
    });

    test('throws TwitchAuthException with status on non-200', () {
      final client = MockClient((request) async => http.Response('nope', 401));

      expect(
        TwitchModerationService(client: client).resolveUnbanRequest(
          accessToken: 'token-1',
          broadcasterId: 'chan-1',
          moderatorId: 'user-1',
          requestId: 'req-1',
          approved: true,
        ),
        throwsA(
          isA<TwitchAuthException>()
              .having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });
  });

  group('warnUser', () {
    test('POSTs moderation/warnings with user id and reason', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://api.twitch.tv/helix/moderation/warnings'
          '?broadcaster_id=chan-1&moderator_id=user-1',
        );
        expect(request.headers['Authorization'], 'Bearer token-1');
        expect(request.headers['Content-Type'], 'application/json');
        expect(json.decode(request.body), {
          'data': {'user_id': 'bad-1', 'reason': 'spoiling movies'},
        });
        return http.Response(json.encode({'data': []}), 200);
      });

      await TwitchModerationService(client: client).warnUser(
        accessToken: 'token-1',
        broadcasterId: 'chan-1',
        moderatorId: 'user-1',
        userId: 'bad-1',
        reason: 'spoiling movies',
      );
    });

    test('throws TwitchAuthException with status on non-200', () {
      final client = MockClient((request) async => http.Response('nope', 403));

      expect(
        TwitchModerationService(client: client).warnUser(
          accessToken: 'token-1',
          broadcasterId: 'chan-1',
          moderatorId: 'user-1',
          userId: 'bad-1',
          reason: 'spoiling movies',
        ),
        throwsA(
          isA<TwitchAuthException>()
              .having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });
  });

  group('getWarnings', () {
    test('GETs moderation/warnings filtered by user id', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.toString(),
          'https://api.twitch.tv/helix/moderation/warnings'
          '?broadcaster_id=chan-1&moderator_id=user-1&user_id=bad-1'
          '&first=100',
        );
        expect(request.headers['Authorization'], 'Bearer token-1');
        return http.Response(
          json.encode({
            'data': [
              {
                'user_id': 'bad-1',
                'user_login': 'troll',
                'user_name': 'Troll',
                'moderator_id': 'user-1',
                'moderator_login': 'kounex',
                'moderator_name': 'Kounex',
                'reason': 'spoiling movies',
                'warned_at': '2026-08-12T10:00:00Z',
              },
            ],
            'pagination': {},
          }),
          200,
        );
      });

      final warnings = await TwitchModerationService(client: client)
          .getWarnings(
        accessToken: 'token-1',
        broadcasterId: 'chan-1',
        moderatorId: 'user-1',
        userId: 'bad-1',
      );

      expect(warnings, hasLength(1));
      expect(warnings[0].userId, 'bad-1');
      expect(warnings[0].reason, 'spoiling movies');
      expect(warnings[0].moderatorName, 'Kounex');
      expect(warnings[0].warnedAt, DateTime.utc(2026, 8, 12, 10));
    });

    test('follows the pagination cursor', () async {
      final requestedAfters = <String?>[];
      final client = MockClient((request) async {
        requestedAfters.add(request.url.queryParameters['after']);
        if (request.url.queryParameters['after'] == null) {
          return http.Response(
            json.encode({
              'data': [
                {'user_id': 'bad-1'},
              ],
              'pagination': {'cursor': 'page-2'},
            }),
            200,
          );
        }
        return http.Response(
          json.encode({
            'data': [
              {'user_id': 'bad-2'},
            ],
            'pagination': {},
          }),
          200,
        );
      });

      final warnings = await TwitchModerationService(client: client)
          .getWarnings(
        accessToken: 'token-1',
        broadcasterId: 'chan-1',
        moderatorId: 'user-1',
        userId: 'bad-1',
      );

      expect(requestedAfters, [null, 'page-2']);
      expect(warnings.map((warning) => warning.userId), ['bad-1', 'bad-2']);
    });

    test('throws TwitchAuthException with status on non-200', () {
      final client = MockClient((request) async => http.Response('nope', 401));

      expect(
        TwitchModerationService(client: client).getWarnings(
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

  group('handleAutoModMessage', () {
    test('POSTs moderation/automod/message with the resolution action',
        () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://api.twitch.tv/helix/moderation/automod/message',
        );
        expect(request.headers['Authorization'], 'Bearer token-1');
        expect(request.headers['Content-Type'], 'application/json');
        expect(json.decode(request.body), {
          'user_id': 'user-1',
          'msg_id': 'msg-held-1',
          'action': 'ALLOW',
        });
        return http.Response('', 204);
      });

      await TwitchModerationService(client: client).handleAutoModMessage(
        accessToken: 'token-1',
        moderatorId: 'user-1',
        messageId: 'msg-held-1',
        allow: true,
      );
    });

    test('sends DENY when allow is false', () async {
      final client = MockClient((request) async {
        expect((json.decode(request.body) as Map<String, dynamic>)['action'],
            'DENY');
        return http.Response('', 204);
      });

      await TwitchModerationService(client: client).handleAutoModMessage(
        accessToken: 'token-1',
        moderatorId: 'user-1',
        messageId: 'msg-held-1',
        allow: false,
      );
    });

    test('throws TwitchAuthException with status on non-204', () {
      final client = MockClient((request) async => http.Response('nope', 400));

      expect(
        TwitchModerationService(client: client).handleAutoModMessage(
          accessToken: 'token-1',
          moderatorId: 'user-1',
          messageId: 'msg-held-1',
          allow: true,
        ),
        throwsA(
          isA<TwitchAuthException>()
              .having((e) => e.statusCode, 'statusCode', 400),
        ),
      );
    });
  });
}
