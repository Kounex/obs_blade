import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/types/classes/youtube/youtube_chat_message.dart';
import 'package:obs_blade/utils/youtube/youtube_live_chat_service.dart';

Map<String, Object?> fixture(String name) =>
    json.decode(
          File('test/chat/fixtures/youtube/$name.json').readAsStringSync(),
        )
        as Map<String, Object?>;

http.Response errorBody(int status, String reason, [String? message]) =>
    http.Response(
      json.encode({
        'error': {
          'code': status,
          'message': message ?? reason,
          'errors': [
            {'reason': reason, 'message': message ?? reason},
          ],
        },
      }),
      status,
    );

void main() {
  YouTubeLiveChatService serviceWith(MockClient client) =>
      YouTubeLiveChatService(client: client);

  group('listMessages', () {
    test('parses the page: messages, nextPageToken, interval, offlineAt, '
        'activePollItem', () async {
      final client = MockClient((request) async {
        expect(request.url.host, 'www.googleapis.com');
        expect(request.url.path, '/youtube/v3/liveChat/messages');
        expect(request.url.queryParameters['liveChatId'], 'chat-1');
        expect(request.url.queryParameters['pageToken'], 'token-1');
        expect(request.url.queryParameters['part'], 'id,snippet,authorDetails');
        expect(request.url.queryParameters['key'], 'api-key-1');
        return http.Response(
          json.encode({
            'nextPageToken': 'token-2',
            'pollingIntervalMillis': 8000,
            'offlineAt': '2026-09-03T11:00:00.000Z',
            'activePollItem': fixture('poll_event'),
            'items': [
              fixture('text_message_event'),
              fixture('super_chat_event'),
            ],
          }),
          200,
        );
      });

      final page = await serviceWith(
        client,
      ).listMessages('chat-1', 'token-1', apiKey: 'api-key-1');

      expect(page.messages, hasLength(2));
      expect(page.messages.first.type, YouTubeChatMessageType.textMessage);
      expect(page.messages[1].type, YouTubeChatMessageType.superChat);
      expect(page.nextPageToken, 'token-2');
      expect(page.pollingIntervalMillis, 8000);
      expect(page.offlineAt, DateTime.utc(2026, 9, 3, 11));
      expect(page.activePollItem?.type, YouTubeChatMessageType.poll);
      expect(
        page.activePollItem?.snippet.pollDetails?.metadata?.questionText,
        'Which game next?',
      );
    });

    test(
      'bearer token goes to the Authorization header, no key param',
      () async {
        final client = MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer access-1');
          expect(request.url.queryParameters.containsKey('key'), isFalse);
          expect(request.url.queryParameters.containsKey('pageToken'), isFalse);
          return http.Response(
            json.encode({'pollingIntervalMillis': 5000, 'items': []}),
            200,
          );
        });

        final page = await serviceWith(
          client,
        ).listMessages('chat-1', null, accessToken: 'access-1');

        expect(page.messages, isEmpty);
        expect(page.nextPageToken, isNull);
        expect(page.offlineAt, isNull);
        expect(page.activePollItem, isNull);
      },
    );

    test('403 quotaExceeded maps to YouTubeQuotaExceededException', () {
      final client = MockClient(
        (request) async => errorBody(403, 'quotaExceeded', 'Quota exceeded'),
      );

      expect(
        serviceWith(client).listMessages('chat-1', null, apiKey: 'k'),
        throwsA(isA<YouTubeQuotaExceededException>()),
      );
    });

    test('429 rateLimitExceeded maps to YouTubeQuotaExceededException', () {
      final client = MockClient(
        (request) async => errorBody(429, 'rateLimitExceeded'),
      );

      expect(
        serviceWith(client).listMessages('chat-1', null, apiKey: 'k'),
        throwsA(isA<YouTubeQuotaExceededException>()),
      );
    });

    test('403 liveChatEnded maps to YouTubeChatEndedException', () {
      final client = MockClient(
        (request) async => errorBody(403, 'liveChatEnded'),
      );

      expect(
        serviceWith(client).listMessages('chat-1', null, apiKey: 'k'),
        throwsA(isA<YouTubeChatEndedException>()),
      );
    });

    test('other 403s map to YouTubeForbiddenException', () {
      final client = MockClient((request) async => errorBody(403, 'forbidden'));

      expect(
        serviceWith(client).listMessages('chat-1', null, apiKey: 'k'),
        throwsA(isA<YouTubeForbiddenException>()),
      );
    });

    test('non-mapped statuses map to the base YouTubeApiException', () {
      final client = MockClient((request) async => http.Response('oops', 500));

      expect(
        serviceWith(client).listMessages('chat-1', null, apiKey: 'k'),
        throwsA(
          isA<YouTubeApiException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having(
                (e) => e,
                'not a subtype',
                isNot(isA<YouTubeForbiddenException>()),
              ),
        ),
      );
    });
  });

  group('insert', () {
    test('posts a textMessageEvent snippet and parses the echo', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/youtube/v3/liveChat/messages');
        expect(request.url.queryParameters['part'], 'snippet');
        expect(request.headers['Authorization'], 'Bearer access-1');
        final body = json.decode(request.body) as Map<String, dynamic>;
        expect(body['snippet']['liveChatId'], 'chat-1');
        expect(body['snippet']['type'], 'textMessageEvent');
        expect(
          body['snippet']['textMessageDetails']['messageText'],
          'hello chat',
        );
        return http.Response(json.encode(fixture('text_message_event')), 200);
      });

      final sent = await serviceWith(client).insert(
        accessToken: 'access-1',
        liveChatId: 'chat-1',
        message: 'hello chat',
      );

      expect(sent.type, YouTubeChatMessageType.textMessage);
      expect(sent.displayText, 'hello from live chat!');
    });

    test('403 forbidden maps to YouTubeForbiddenException (not a mod)', () {
      final client = MockClient((request) async => errorBody(403, 'forbidden'));

      expect(
        serviceWith(
          client,
        ).insert(accessToken: 'a', liveChatId: 'c', message: 'm'),
        throwsA(isA<YouTubeForbiddenException>()),
      );
    });
  });

  group('delete', () {
    test('issues DELETE with the message id, 204 succeeds', () async {
      final client = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/youtube/v3/liveChat/messages');
        expect(request.url.queryParameters['id'], 'msg-1');
        expect(request.headers['Authorization'], 'Bearer access-1');
        return http.Response('', 204);
      });

      await serviceWith(
        client,
      ).delete(accessToken: 'access-1', messageId: 'msg-1');
    });

    test('non-204 throws', () {
      final client = MockClient(
        (request) async =>
            errorBody(403, 'liveChatUserBannedCommentDeletionNotAllowed'),
      );

      expect(
        serviceWith(client).delete(accessToken: 'a', messageId: 'msg-1'),
        throwsA(isA<YouTubeForbiddenException>()),
      );
    });
  });

  group('ban / unban', () {
    test('temporary ban carries type + duration', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/youtube/v3/liveChat/bans');
        final body = json.decode(request.body) as Map<String, dynamic>;
        expect(body['snippet']['liveChatId'], 'chat-1');
        expect(body['snippet']['type'], 'temporary');
        expect(body['snippet']['banDurationSeconds'], 300);
        expect(body['snippet']['bannedUserDetails']['channelId'], 'UCBad');
        return http.Response(json.encode({'id': 'ban-1'}), 200);
      });

      await serviceWith(client).ban(
        accessToken: 'access-1',
        liveChatId: 'chat-1',
        channelId: 'UCBad',
        durationSeconds: 300,
      );
    });

    test('permanent ban omits the duration', () async {
      final client = MockClient((request) async {
        final body = json.decode(request.body) as Map<String, dynamic>;
        expect(body['snippet']['type'], 'permanent');
        expect(
          (body['snippet'] as Map).containsKey('banDurationSeconds'),
          isFalse,
        );
        return http.Response(json.encode({'id': 'ban-1'}), 200);
      });

      await serviceWith(
        client,
      ).ban(accessToken: 'access-1', liveChatId: 'chat-1', channelId: 'UCBad');
    });

    test('unban issues DELETE liveChat/bans?id=, 204 succeeds', () async {
      final client = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/youtube/v3/liveChat/bans');
        expect(request.url.queryParameters['id'], 'ban-1');
        return http.Response('', 204);
      });

      await serviceWith(client).unban(accessToken: 'access-1', banId: 'ban-1');
    });
  });

  group('getActiveLiveChatId', () {
    test('parses liveStreamingDetails.activeLiveChatId', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/youtube/v3/videos');
        expect(request.url.queryParameters['part'], 'liveStreamingDetails');
        expect(request.url.queryParameters['id'], 'video-1');
        expect(request.url.queryParameters['key'], 'api-key-1');
        return http.Response(
          json.encode({
            'items': [
              {
                'id': 'video-1',
                'liveStreamingDetails': {'activeLiveChatId': 'chat-1'},
              },
            ],
          }),
          200,
        );
      });

      final chatId = await serviceWith(
        client,
      ).getActiveLiveChatId('video-1', apiKey: 'api-key-1');

      expect(chatId, 'chat-1');
    });

    test('null when the video is not live / has no active chat', () async {
      final client = MockClient(
        (request) async => http.Response(
          json.encode({
            'items': [
              {'id': 'video-2'},
            ],
          }),
          200,
        ),
      );

      expect(
        await serviceWith(
          client,
        ).getActiveLiveChatId('video-2', apiKey: 'api-key-1'),
        isNull,
      );
    });

    test('null when the video id does not exist (empty items)', () async {
      final client = MockClient(
        (request) async => http.Response(json.encode({'items': []}), 200),
      );

      expect(
        await serviceWith(
          client,
        ).getActiveLiveChatId('missing', apiKey: 'api-key-1'),
        isNull,
      );
    });
  });
}
