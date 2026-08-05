import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';
import 'package:obs_blade/utils/twitch/twitch_badge_service.dart';

const _kBadgesBody = {
  'data': [
    {
      'set_id': 'subscriber',
      'versions': [
        {
          'id': '12',
          'image_url_1x': 'https://cdn/sub/1.png',
          'image_url_2x': 'https://cdn/sub/2.png',
          'image_url_4x': 'https://cdn/sub/3.png',
          'title': '1-Year Subscriber',
        },
      ],
    },
  ],
};

void main() {
  group('fetchGlobalBadges', () {
    test('calls the global endpoint with helix headers and parses sets',
        () async {
      final client = MockClient((request) async {
        expect(request.url.toString(),
            'https://api.twitch.tv/helix/chat/badges/global');
        expect(request.headers['Authorization'], 'Bearer token-1');
        expect(request.headers['Client-Id'], kTwitchClientId);
        return http.Response(json.encode(_kBadgesBody), 200);
      });

      final sets = await TwitchBadgeService(client: client)
          .fetchGlobalBadges('token-1');

      expect(sets, hasLength(1));
      expect(sets.single.setId, 'subscriber');
      expect(sets.single.versions.single.imageUrl2x, 'https://cdn/sub/2.png');
    });
  });

  group('fetchChannelBadges', () {
    test('passes the broadcaster id as query param', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(),
            'https://api.twitch.tv/helix/chat/badges?broadcaster_id=user-1');
        return http.Response(json.encode(_kBadgesBody), 200);
      });

      final sets = await TwitchBadgeService(client: client)
          .fetchChannelBadges('token-1', 'user-1');

      expect(sets.single.setId, 'subscriber');
    });

    test('throws TwitchAuthException with status on non-200', () {
      final client = MockClient((request) async => http.Response('nope', 401));

      expect(
        TwitchBadgeService(client: client)
            .fetchChannelBadges('token-1', 'user-1'),
        throwsA(
          isA<TwitchAuthException>()
              .having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });
  });
}
