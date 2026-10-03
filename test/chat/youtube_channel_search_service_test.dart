import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/utils/youtube/youtube_channel_search_service.dart';
import 'package:obs_blade/utils/youtube/youtube_entry_name.dart';
import 'package:obs_blade/utils/youtube/youtube_live_chat_service.dart';
import 'package:obs_blade/utils/youtube_target.dart';

/// Shapes follow Google's reference for `search#searchListResponse`,
/// `subscriptionListResponse` and `channelListResponse` (search channel
/// hits carry `id.channelId` + `snippet.liveBroadcastContent`, no
/// handle; subscriptions carry `snippet.resourceId.channelId`).
Map<String, Object?> searchHit(
  String id,
  String title, {
  String live = 'none',
}) => {
  'kind': 'youtube#searchResult',
  'id': {'kind': 'youtube#channel', 'channelId': id},
  'snippet': {
    'channelId': id,
    'title': title,
    'channelTitle': title,
    'description': '',
    'liveBroadcastContent': live,
  },
};

Map<String, Object?> channelItem(
  String id, {
  String? customUrl,
  String? subscribers,
  bool hidden = false,
}) => {
  'kind': 'youtube#channel',
  'id': id,
  'snippet': {'title': 'x', 'customUrl': ?customUrl},
  'statistics': {
    'subscriberCount': ?subscribers,
    'hiddenSubscriberCount': hidden,
  },
};

http.Response errorResponse(int code, String reason) => http.Response(
  json.encode({
    'error': {
      'code': code,
      'message': reason,
      'errors': [
        {'reason': reason, 'domain': 'youtube.quota'},
      ],
    },
  }),
  code,
);

const String kUcA = 'UCaaaaaaaaaaaaaaaaaaaaaa';
const String kUcB = 'UCbbbbbbbbbbbbbbbbbbbbbb';

void main() {
  group('searchChannels', () {
    test('searches channels with the key, enriches handle + subscribers, '
        'and caches the answer', () async {
      final paths = <String>[];
      final client = MockClient((request) async {
        paths.add(request.url.path);
        expect(request.url.queryParameters['key'], 'key-1');
        if (request.url.path.endsWith('/search')) {
          expect(request.url.queryParameters['type'], 'channel');
          expect(request.url.queryParameters['q'], 'markiplier');
          return http.Response(
            json.encode({
              'items': [
                searchHit(kUcA, 'Markiplier', live: 'live'),
                searchHit(kUcB, 'Markiplier Clips'),
              ],
            }),
            200,
          );
        }
        expect(request.url.queryParameters['id'], '$kUcA,$kUcB');
        return http.Response(
          json.encode({
            'items': [
              channelItem(
                kUcA,
                customUrl: '@markiplier',
                subscribers: '37200000',
              ),
              channelItem(kUcB, subscribers: '900', hidden: true),
            ],
          }),
          200,
        );
      });
      final service = YouTubeChannelSearchService(client: client);

      final results = await service.searchChannels(
        'markiplier',
        apiKey: 'key-1',
      );

      expect(results.map((r) => r.channelId), [kUcA, kUcB]);
      expect(results[0].isLive, isTrue);
      expect(results[0].handle, '@markiplier');
      expect(results[0].subscriberCount, 37200000);
      expect(results[1].isLive, isFalse);
      expect(results[1].subscriberCount, isNull, reason: 'hidden count');

      final again = await service.searchChannels(
        'Markiplier ',
        apiKey: 'key-1',
      );
      expect(again, same(results));
      expect(service.cached('markiplier'), same(results));
      expect(paths.length, 2, reason: 'second search answered from cache');
    });

    test('a failed enrich keeps the bare hits', () async {
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/search')) {
          return http.Response(
            json.encode({
              'items': [searchHit(kUcA, 'Alpha')],
            }),
            200,
          );
        }
        return errorResponse(403, 'quotaExceeded');
      });

      final results = await YouTubeChannelSearchService(
        client: client,
      ).searchChannels('alpha', apiKey: 'k');

      expect(results.single.title, 'Alpha');
      expect(results.single.handle, isNull);
    });

    test('the used-up daily search bucket surfaces as quota exceeded', () {
      final client = MockClient(
        (request) async => errorResponse(403, 'quotaExceeded'),
      );

      expect(
        () => YouTubeChannelSearchService(
          client: client,
        ).searchChannels('alpha', apiKey: 'k'),
        throwsA(isA<YouTubeQuotaExceededException>()),
      );
    });

    test('a bad key surfaces as forbidden', () {
      final client = MockClient(
        (request) async => errorResponse(400, 'keyInvalid'),
      );

      expect(
        () => YouTubeChannelSearchService(
          client: client,
        ).searchChannels('alpha', apiKey: 'k'),
        throwsA(isA<YouTubeApiException>()),
      );
    });

    test('under 3 characters there is no request', () async {
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        return http.Response('{}', 200);
      });

      final results = await YouTubeChannelSearchService(
        client: client,
      ).searchChannels('ab', apiKey: 'k');

      expect(results, isEmpty);
      expect(calls, 0);
    });
  });

  group('listSubscriptions', () {
    Map<String, Object?> subscription(String id, String title) => {
      'kind': 'youtube#subscription',
      'snippet': {
        'title': title,
        'resourceId': {'kind': 'youtube#channel', 'channelId': id},
      },
    };

    test('pages A-Z with the bearer token', () async {
      final pageTokens = <String?>[];
      final client = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer token-1');
        if (request.url.path.endsWith('/channels')) {
          return http.Response('{"items": []}', 200);
        }
        expect(request.url.queryParameters['mine'], 'true');
        expect(request.url.queryParameters['order'], 'alphabetical');
        final token = request.url.queryParameters['pageToken'];
        pageTokens.add(token);
        return http.Response(
          json.encode(
            token == null
                ? {
                    'nextPageToken': 'p2',
                    'items': [subscription(kUcA, 'Alpha')],
                  }
                : {
                    'items': [subscription(kUcB, 'Beta')],
                  },
          ),
          200,
        );
      });

      final subscriptions = await YouTubeChannelSearchService(
        client: client,
      ).listSubscriptions(accessToken: 'token-1');

      expect(subscriptions.map((s) => s.title), ['Alpha', 'Beta']);
      expect(subscriptions.first.channelId, kUcA);
      expect(pageTokens, [null, 'p2']);
    });

    test(
      'an account without a channel (subscriberNotFound) has none',
      () async {
        final client = MockClient(
          (request) async => errorResponse(404, 'subscriberNotFound'),
        );

        final subscriptions = await YouTubeChannelSearchService(
          client: client,
        ).listSubscriptions(accessToken: 't');

        expect(subscriptions, isEmpty);
      },
    );

    test('a dead token throws forbidden', () {
      final client = MockClient(
        (request) async => errorResponse(401, 'authError'),
      );

      expect(
        () => YouTubeChannelSearchService(
          client: client,
        ).listSubscriptions(accessToken: 't'),
        throwsA(isA<YouTubeForbiddenException>()),
      );
    });
  });

  group('cache + aliases', () {
    test(
      'cached answers expire after the TTL (LIVE must not go stale)',
      () async {
        var now = DateTime.utc(2026, 10, 3, 12);
        var calls = 0;
        final client = MockClient((request) async {
          if (request.url.path.endsWith('/search')) calls++;
          return http.Response(
            json.encode({
              'items': [searchHit(kUcA, 'Alpha', live: 'live')],
            }),
            200,
          );
        });
        final service = YouTubeChannelSearchService(
          client: client,
          now: () => now,
        );

        await service.searchChannels('alpha', apiKey: 'k');
        now = now.add(const Duration(minutes: 9));
        expect(service.cached('alpha'), isNotNull);
        await service.searchChannels('alpha', apiKey: 'k');
        expect(calls, 1);

        now = now.add(const Duration(minutes: 2));
        expect(service.cached('alpha'), isNull);
        await service.searchChannels('alpha', apiKey: 'k');
        expect(calls, 2);
      },
    );

    test('an @handle resolves to its UC id (forHandle), an id to its '
        'handle (customUrl)', () async {
      final client = MockClient((request) async {
        final query = request.url.queryParameters;
        if (query['forHandle'] == '@beta') {
          return http.Response(
            json.encode({
              'items': [channelItem(kUcB, customUrl: '@beta')],
            }),
            200,
          );
        }
        if (query['id'] == kUcB) {
          return http.Response(
            json.encode({
              'items': [channelItem(kUcB, customUrl: '@beta')],
            }),
            200,
          );
        }
        return http.Response('{"items": []}', 200);
      });
      final service = YouTubeChannelSearchService(client: client);

      expect(
        await service.aliasKeysFor(
          const YouTubeChannelTarget('@beta'),
          apiKey: 'k',
        ),
        {const YouTubeChannelTarget('channel/$kUcB').key},
      );
      expect(
        await service.aliasKeysFor(
          const YouTubeChannelTarget('channel/$kUcB'),
          apiKey: 'k',
        ),
        {const YouTubeChannelTarget('@beta').key},
      );
      expect(
        await service.aliasKeysFor(
          const YouTubeChannelTarget('@nobody'),
          apiKey: 'k',
        ),
        isEmpty,
      );
    });

    test('a failed alias lookup is empty, never an error', () async {
      final client = MockClient(
        (request) async => errorResponse(403, 'quotaExceeded'),
      );

      expect(
        await YouTubeChannelSearchService(
          client: client,
        ).aliasKeysFor(const YouTubeChannelTarget('@beta'), apiKey: 'k'),
        isEmpty,
      );
    });
  });

  group('youTubeEntryLabelFor', () {
    test('an already listed target keeps its label, by id or handle', () {
      final entries = {'Mark': '@markiplier', 'Other': kUcB};

      expect(
        youTubeEntryLabelFor(
          const YouTubeChannelTarget('@MarkIplier'),
          'Markiplier',
          entries,
        ),
        (label: 'Mark', value: '@markiplier', existing: true),
      );
      expect(
        youTubeEntryLabelFor(
          const YouTubeChannelTarget('channel/$kUcB'),
          'Beta',
          entries,
        ),
        (label: 'Other', value: kUcB, existing: true),
      );
    });

    test('the other stored form finds the entry through its alias', () {
      final entries = {'Beta': '@beta'};

      expect(
        youTubeEntryLabelFor(
          const YouTubeChannelTarget('channel/$kUcB'),
          'Beta TV',
          entries,
          aliasKeys: {const YouTubeChannelTarget('@beta').key},
        ),
        (label: 'Beta', value: '@beta', existing: true),
      );
      expect(
        youTubeEntryLabelFor(
          const YouTubeChannelTarget('channel/$kUcB'),
          'Beta TV',
          entries,
        ).existing,
        isFalse,
        reason: 'without the alias the two forms are different targets',
      );
    });

    test('a new target gets its name, made unique', () {
      expect(
        youTubeEntryLabelFor(
          const YouTubeChannelTarget('channel/$kUcA'),
          'Mark',
          {'Mark': '@markiplier'},
        ),
        (label: 'Mark (2)', value: kUcA, existing: false),
      );
    });
  });
}
