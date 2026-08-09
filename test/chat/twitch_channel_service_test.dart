import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/types/classes/twitch/twitch_channel_ref.dart';
import 'package:obs_blade/types/classes/twitch/twitch_channel_search_result.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';
import 'package:obs_blade/utils/twitch/twitch_channel_service.dart';

void main() {
  group('searchChannels', () {
    test('GETs the search endpoint with query/first and parses results',
        () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(),
            'https://api.twitch.tv/helix/search/channels?query=ninja&first=20');
        expect(request.headers['Authorization'], 'Bearer token-1');
        expect(request.headers['Client-Id'], kTwitchClientId);
        return http.Response(
          json.encode({
            'data': [
              {
                'id': 'chan-1',
                'broadcaster_login': 'ninja',
                'display_name': 'Ninja',
                'game_name': 'Fortnite',
                'is_live': true,
              },
              {
                'id': 'chan-2',
                'broadcaster_login': 'ninjascousin',
                'display_name': 'NinjasCousin',
                'game_name': '',
                'is_live': false,
              },
            ],
          }),
          200,
        );
      });

      final results = await TwitchChannelService(client: client)
          .searchChannels(accessToken: 'token-1', query: 'ninja');

      expect(results, hasLength(2));
      expect(results[0].id, 'chan-1');
      expect(results[0].login, 'ninja');
      expect(results[0].displayName, 'Ninja');
      expect(results[0].gameName, 'Fortnite');
      expect(results[0].isLive, isTrue);
      expect(results[1].isLive, isFalse);
      expect(results[1].gameName, isEmpty);
    });

    test('encodes a query with spaces', () async {
      final client = MockClient((request) async {
        expect(request.url.queryParameters['query'], 'some one');
        return http.Response(json.encode({'data': []}), 200);
      });

      final results = await TwitchChannelService(client: client)
          .searchChannels(accessToken: 'token-1', query: 'some one');

      expect(results, isEmpty);
    });

    test('throws TwitchAuthException with status on non-200', () {
      final client = MockClient((request) async => http.Response('nope', 403));

      expect(
        TwitchChannelService(client: client)
            .searchChannels(accessToken: 'token-1', query: 'ninja'),
        throwsA(
          isA<TwitchAuthException>()
              .having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });
  });

  group('getModeratedChannels', () {
    test('GETs user_id/first=100 and parses refs', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(),
            'https://api.twitch.tv/helix/moderation/channels?user_id=user-1&first=100');
        expect(request.headers['Authorization'], 'Bearer token-1');
        expect(request.headers['Client-Id'], kTwitchClientId);
        return http.Response(
          json.encode({
            'data': [
              {
                'broadcaster_id': 'chan-1',
                'broadcaster_login': 'friend',
                'broadcaster_name': 'Friend',
              },
            ],
            'pagination': {},
          }),
          200,
        );
      });

      final refs = await TwitchChannelService(client: client)
          .getModeratedChannels(accessToken: 'token-1', userId: 'user-1');

      expect(refs, hasLength(1));
      expect(refs.single.id, 'chan-1');
      expect(refs.single.login, 'friend');
      expect(refs.single.displayName, 'Friend');
    });

    test('follows one pagination cursor and merges both pages', () async {
      final urls = <String>[];
      final client = MockClient((request) async {
        urls.add(request.url.toString());
        if (!request.url.queryParameters.containsKey('after')) {
          return http.Response(
            json.encode({
              'data': [
                {
                  'broadcaster_id': 'chan-1',
                  'broadcaster_login': 'one',
                  'broadcaster_name': 'One',
                },
              ],
              'pagination': {'cursor': 'cursor-1'},
            }),
            200,
          );
        }
        expect(request.url.queryParameters['after'], 'cursor-1');
        return http.Response(
          json.encode({
            'data': [
              {
                'broadcaster_id': 'chan-2',
                'broadcaster_login': 'two',
                'broadcaster_name': 'Two',
              },
            ],
            'pagination': {'cursor': 'cursor-2'},
          }),
          200,
        );
      });

      final refs = await TwitchChannelService(client: client)
          .getModeratedChannels(accessToken: 'token-1', userId: 'user-1');

      expect(refs.map((ref) => ref.id), ['chan-1', 'chan-2']);
      expect(urls, hasLength(2));
    });

    test('throws TwitchAuthException with status on non-200', () {
      final client = MockClient((request) async => http.Response('nope', 401));

      expect(
        TwitchChannelService(client: client)
            .getModeratedChannels(accessToken: 'token-1', userId: 'user-1'),
        throwsA(
          isA<TwitchAuthException>()
              .having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });
  });

  group('sortChannelPickerRefs', () {
    TwitchChannelRef ref(String id) => TwitchChannelRef(
          id: id,
          login: id,
          displayName: id,
          addedAt: DateTime.utc(2026, 8, 9),
        );

    test('orders live, then mod, then the rest — stable within a tier', () {
      final sorted = sortChannelPickerRefs(
        [ref('a'), ref('b'), ref('c'), ref('d'), ref('e')],
        liveIds: {'c', 'e'},
        modIds: {'b', 'e'},
      );
      expect(sorted.map((r) => r.id), ['c', 'e', 'b', 'a', 'd']);
    });
  });

  group('sortChannelSearchResults', () {
    TwitchChannelSearchResult result(String id, {bool live = false}) =>
        TwitchChannelSearchResult(
          id: id,
          login: id,
          displayName: id,
          gameName: '',
          isLive: live,
        );

    test('orders live, then mod, then the rest — stable within a tier', () {
      final sorted = sortChannelSearchResults(
        [
          result('offline'),
          result('mod-only'),
          result('live-b', live: true),
          result('live-a', live: true),
          result('live-mod', live: true),
        ],
        modIds: {'mod-only', 'live-mod'},
      );
      expect(
        sorted.map((r) => r.id),
        ['live-b', 'live-a', 'live-mod', 'mod-only', 'offline'],
      );
    });
  });

  group('getLiveBroadcasterIds', () {
    test('GETs /streams with repeated user_id and returns live ids', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/helix/streams');
        expect(request.url.queryParametersAll['user_id'],
            ['chan-1', 'chan-2', 'chan-3']);
        return http.Response(
          json.encode({
            'data': [
              {'user_id': 'chan-1', 'type': 'live'},
              {'user_id': 'chan-3', 'type': 'live'},
            ],
          }),
          200,
        );
      });

      final live = await TwitchChannelService(client: client)
          .getLiveBroadcasterIds(
        accessToken: 'token-1',
        broadcasterIds: ['chan-1', 'chan-2', 'chan-3'],
      );

      expect(live, {'chan-1', 'chan-3'});
    });

    test('empty input skips the request', () async {
      var called = false;
      final client = MockClient((request) async {
        called = true;
        return http.Response('{}', 200);
      });

      final live = await TwitchChannelService(client: client)
          .getLiveBroadcasterIds(
        accessToken: 'token-1',
        broadcasterIds: const [],
      );

      expect(live, isEmpty);
      expect(called, isFalse);
    });

    test('throws TwitchAuthException with status on non-200', () {
      final client = MockClient((request) async => http.Response('nope', 401));

      expect(
        TwitchChannelService(client: client).getLiveBroadcasterIds(
          accessToken: 'token-1',
          broadcasterIds: ['chan-1'],
        ),
        throwsA(
          isA<TwitchAuthException>()
              .having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });
  });

  group('getFollowedChannels', () {
    test('GETs user_id/first=100 and parses refs', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(),
            'https://api.twitch.tv/helix/channels/followed?user_id=user-1&first=100');
        expect(request.headers['Authorization'], 'Bearer token-1');
        return http.Response(
          json.encode({
            'data': [
              {
                'broadcaster_id': 'chan-9',
                'broadcaster_login': 'fav',
                'broadcaster_name': 'Fav',
                'followed_at': '2026-01-01T00:00:00Z',
              },
            ],
            'pagination': {},
          }),
          200,
        );
      });

      final refs = await TwitchChannelService(client: client)
          .getFollowedChannels(accessToken: 'token-1', userId: 'user-1');

      expect(refs.single.id, 'chan-9');
      expect(refs.single.login, 'fav');
      expect(refs.single.displayName, 'Fav');
    });

    test('empty data yields an empty list', () async {
      final client = MockClient((request) async =>
          http.Response(json.encode({'data': [], 'pagination': {}}), 200));

      final refs = await TwitchChannelService(client: client)
          .getFollowedChannels(accessToken: 'token-1', userId: 'user-1');

      expect(refs, isEmpty);
    });

    test('throws TwitchAuthException with status on non-200', () {
      final client = MockClient((request) async => http.Response('nope', 500));

      expect(
        TwitchChannelService(client: client)
            .getFollowedChannels(accessToken: 'token-1', userId: 'user-1'),
        throwsA(
          isA<TwitchAuthException>()
              .having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });
  });
}
