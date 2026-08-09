import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';
import 'package:obs_blade/utils/twitch/twitch_user_service.dart';

void main() {
  const token = 'token-1';

  group('fetchUser', () {
    test('GETs /users?id= and parses the first entry', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(),
            'https://api.twitch.tv/helix/users?id=user-42');
        expect(request.headers['Authorization'], 'Bearer $token');
        expect(request.headers['Client-Id'], kTwitchClientId);
        return http.Response(
          json.encode({
            'data': [
              {
                'id': 'user-42',
                'login': 'viewer',
                'display_name': 'Viewer',
                'profile_image_url': 'https://example/a.png',
                'created_at': '2016-03-10T15:45:00Z',
              },
            ],
          }),
          200,
        );
      });

      final user = await TwitchUserService(client: client).fetchUser(
        accessToken: token,
        userId: 'user-42',
      );

      expect(user?.id, 'user-42');
      expect(user?.login, 'viewer');
      expect(user?.displayName, 'Viewer');
      expect(user?.createdAt, DateTime.utc(2016, 3, 10, 15, 45));
    });

    test('403 returns null', () async {
      final client = MockClient((_) async => http.Response('nope', 403));

      final user = await TwitchUserService(client: client).fetchUser(
        accessToken: token,
        userId: 'user-42',
      );

      expect(user, isNull);
    });
  });

  group('followerSince', () {
    test('maps followed_at from channels/followers', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/helix/channels/followers');
        expect(request.url.queryParameters['broadcaster_id'], 'broad-1');
        expect(request.url.queryParameters['user_id'], 'user-2');
        return http.Response(
          json.encode({
            'data': [
              {'followed_at': '2020-01-15T12:00:00Z'},
            ],
          }),
          200,
        );
      });

      final when = await TwitchUserService(client: client).followerSince(
        accessToken: token,
        broadcasterId: 'broad-1',
        userId: 'user-2',
      );

      expect(when, DateTime.utc(2020, 1, 15, 12));
    });

    test('403 returns null', () async {
      final client = MockClient((_) async => http.Response('', 403));

      final when = await TwitchUserService(client: client).followerSince(
        accessToken: token,
        broadcasterId: 'broad-1',
        userId: 'user-2',
      );

      expect(when, isNull);
    });
  });

  group('selfFollowedAt', () {
    test('maps followed_at from channels/followed', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/helix/channels/followed');
        expect(request.url.queryParameters['user_id'], 'self-1');
        expect(request.url.queryParameters['broadcaster_id'], 'broad-1');
        return http.Response(
          json.encode({
            'data': [
              {'followed_at': '2019-06-01T08:30:00Z'},
            ],
          }),
          200,
        );
      });

      final when = await TwitchUserService(client: client).selfFollowedAt(
        accessToken: token,
        userId: 'self-1',
        broadcasterId: 'broad-1',
      );

      expect(when, DateTime.utc(2019, 6, 1, 8, 30));
    });
  });

  group('selfSubscription', () {
    test('maps tier and cumulative_months', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/helix/subscriptions/user');
        expect(request.url.queryParameters['broadcaster_id'], 'broad-1');
        return http.Response(
          json.encode({
            'data': [
              {
                'broadcaster_id': 'broad-1',
                'tier': '2000',
                'cumulative_months': 14,
              },
            ],
          }),
          200,
        );
      });

      final sub = await TwitchUserService(client: client).selfSubscription(
        accessToken: token,
        broadcasterId: 'broad-1',
      );

      expect(sub?.tier, '2000');
      expect(sub?.months, 14);
    });

    test('404 returns null', () async {
      final client = MockClient((_) async => http.Response('', 404));

      final sub = await TwitchUserService(client: client).selfSubscription(
        accessToken: token,
        broadcasterId: 'broad-1',
      );

      expect(sub, isNull);
    });
  });
}
