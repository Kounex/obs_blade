import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/utils/kick/kick_channel_service.dart'
    show KickApiException;
import 'package:obs_blade/utils/kick/kick_emote_service.dart';

/// Mirrors the verified live shape of `GET https://kick.com/emotes/{slug}`
/// (2026-09-23, against a real channel): an array of THREE entries — the
/// channel's own set first (no `name` field), then Kick's platform-wide
/// `Global` and `Emojis` sets (each carrying a `name`).
const _kResponseBody = [
  {
    'id': 668,
    'slug': 'xqc',
    'emotes': [
      {'id': 1, 'channel_id': 668, 'name': 'xqcL', 'subscribers_only': false},
      {'id': 2, 'channel_id': 668, 'name': 'xqcHype', 'subscribers_only': true},
    ],
  },
  {
    'name': 'Global',
    'id': 'Global',
    'emotes': [
      {
        'id': 100,
        'channel_id': null,
        'name': 'PogChamp',
        'subscribers_only': false,
      },
    ],
  },
  {
    'name': 'Emojis',
    'id': 'Emoji',
    'emotes': [
      {
        'id': 200,
        'channel_id': null,
        'name': 'emojiAngel',
        'subscribers_only': false,
      },
    ],
  },
];

void main() {
  group('fetchChannelEmotes', () {
    test('parses Channel / Global / Emojis sections in order', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), 'https://kick.com/emotes/xqc');
        expect(request.headers['User-Agent'], 'OBSBlade');
        return http.Response(json.encode(_kResponseBody), 200);
      });

      final sections = await KickEmoteService(
        client: client,
      ).fetchChannelEmotes('xqc');

      expect(sections, hasLength(3));
      expect(sections[0].label, 'Channel');
      expect(sections[0].emotes.map((e) => e.name), ['xqcL', 'xqcHype']);
      expect(sections[0].emotes[1].subscribersOnly, isTrue);
      expect(sections[1].label, 'Global');
      expect(sections[1].emotes.single.name, 'PogChamp');
      expect(sections[2].label, 'Emojis');
      expect(sections[2].emotes.single.name, 'emojiAngel');
    });

    test('a malformed emote entry is skipped, not fatal', () async {
      final client = MockClient(
        (request) async => http.Response(
          json.encode([
            {
              'id': 668,
              'emotes': [
                {'id': 1, 'name': 'Good', 'subscribers_only': false},
                {'no': 'id or name here'},
              ],
            },
          ]),
          200,
        ),
      );

      final sections = await KickEmoteService(
        client: client,
      ).fetchChannelEmotes('xqc');

      expect(sections.single.emotes.map((e) => e.name), ['Good']);
    });

    test('an empty-emotes entry is dropped entirely', () async {
      final client = MockClient(
        (request) async => http.Response(
          json.encode([
            {'id': 668, 'emotes': <Object?>[]},
            {
              'name': 'Global',
              'emotes': [
                {'id': 100, 'name': 'PogChamp', 'subscribers_only': false},
              ],
            },
          ]),
          200,
        ),
      );

      final sections = await KickEmoteService(
        client: client,
      ).fetchChannelEmotes('xqc');

      expect(sections, hasLength(1));
      expect(sections.single.label, 'Global');
    });

    test('a non-200 response throws KickApiException', () async {
      final client = MockClient(
        (request) async => http.Response('server error', 500),
      );

      expect(
        () => KickEmoteService(client: client).fetchChannelEmotes('xqc'),
        throwsA(
          isA<KickApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            500,
          ),
        ),
      );
    });

    test('a non-list response body returns no sections', () async {
      final client = MockClient(
        (request) async => http.Response(json.encode({'error': 'nope'}), 200),
      );

      final sections = await KickEmoteService(
        client: client,
      ).fetchChannelEmotes('xqc');

      expect(sections, isEmpty);
    });
  });
}
