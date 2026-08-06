import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';
import 'package:obs_blade/utils/twitch/twitch_emote_service.dart';

/// Mirrors the Helix `chat/emotes/user` `data[]` shape (we read id, name,
/// owner_id and keep emote_type/emote_set_id raw).
Map<String, Object?> emoteEntry(String id, String name, String ownerId) => {
      'id': id,
      'name': name,
      'tier': '1000',
      'emote_type': 'subscriptions',
      'emote_set_id': 'set-$id',
      'owner_id': ownerId,
      'format': ['static'],
      'scale_available': ['1', '2', '3'],
      'theme_mode': ['light', 'dark'],
    };

void main() {
  group('fetchUserEmotes', () {
    test('parses a single page and sends the helix headers', () async {
      final client = MockClient((request) async {
        expect(
          request.url.toString(),
          'https://api.twitch.tv/helix/chat/emotes/user'
          '?user_id=user-1&broadcaster_id=user-1',
        );
        expect(request.headers['Authorization'], 'Bearer token-1');
        expect(request.headers['Client-Id'], kTwitchClientId);
        return http.Response(
          json.encode({
            'data': [
              emoteEntry('25', 'Kappa', 'user-1'),
              emoteEntry('88', 'PogChamp', 'twitch'),
              {'name': 'broken-no-id', 'owner_id': 'user-1'},
            ],
          }),
          200,
        );
      });

      final emotes = await TwitchEmoteService(client: client)
          .fetchUserEmotes('token-1', userId: 'user-1', broadcasterId: 'user-1');

      expect(emotes, hasLength(2));
      expect(emotes[0].id, '25');
      expect(emotes[0].name, 'Kappa');
      expect(emotes[0].ownerId, 'user-1');
      expect(emotes[0].emoteType, 'subscriptions');
      expect(emotes[1].ownerId, 'twitch');
    });

    test('accumulates pages via the after cursor', () async {
      final urls = <String>[];
      final client = MockClient((request) async {
        urls.add(request.url.toString());
        if (urls.length == 1) {
          return http.Response(
            json.encode({
              'data': [emoteEntry('25', 'Kappa', 'user-1')],
              'pagination': {'cursor': 'next/page?'},
            }),
            200,
          );
        }
        return http.Response(
          json.encode({
            'data': [emoteEntry('88', 'PogChamp', 'twitch')],
            'pagination': {},
          }),
          200,
        );
      });

      final emotes = await TwitchEmoteService(client: client)
          .fetchUserEmotes('token-1', userId: 'user-1', broadcasterId: 'user-1');

      expect(emotes.map((e) => e.name), ['Kappa', 'PogChamp']);
      expect(urls, hasLength(2));
      expect(urls[1], contains('&after=next%2Fpage%3F'));
    });

    test('non-200 throws TwitchAuthException with status', () {
      final client = MockClient((request) async => http.Response('nope', 401));

      expect(
        TwitchEmoteService(client: client).fetchUserEmotes(
          'token-1',
          userId: 'user-1',
          broadcasterId: 'user-1',
        ),
        throwsA(isA<TwitchAuthException>()
            .having((e) => e.statusCode, 'statusCode', 401)),
      );
    });

    test('a 200 without a data list throws TwitchAuthException', () {
      final client = MockClient((request) async =>
          http.Response(json.encode({'unexpected': true}), 200));

      expect(
        TwitchEmoteService(client: client).fetchUserEmotes(
          'token-1',
          userId: 'user-1',
          broadcasterId: 'user-1',
        ),
        throwsA(isA<TwitchAuthException>()),
      );
    });
  });
}
