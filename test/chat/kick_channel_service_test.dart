import 'dart:convert';

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/utils/kick/kick_channel_service.dart';

void main() {
  test('resolveChannel sends a non-browser User-Agent', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/v2/channels/deenthegreat');
      expect(request.headers['user-agent'], kKickUserAgent);
      expect(
        request.headers['user-agent']!.toLowerCase(),
        isNot(contains('mozilla')),
      );
      return http.Response(
        json.encode({
          'id': 1,
          'user_id': 2,
          'slug': 'deenthegreat',
          'chatroom': {'id': 9},
        }),
        200,
      );
    });

    final info = await KickChannelService(
      client: client,
    ).resolveChannel('deenthegreat');

    expect(info?.chatroomId, 9);
    expect(info?.slug, 'deenthegreat');
  });

  group('searchChannels', () {
    /// Real `kick.com/api/search?searched_word=xqc` answer, trimmed to
    /// three channels (captured 2026-10-03).
    final fixture = File(
      'test/chat/fixtures/kick/search_xqc.json',
    ).readAsStringSync();

    test('parses the website search answer', () async {
      late Uri seen;
      final client = MockClient((request) async {
        seen = request.url;
        expect(request.headers['user-agent'], kKickUserAgent);
        return http.Response(fixture, 200);
      });

      final results = await KickChannelService(
        client: client,
      ).searchChannels(' xqc ');

      expect(seen.host, 'kick.com');
      expect(seen.path, '/api/search');
      expect(seen.queryParameters['searched_word'], 'xqc');
      expect(results.map((c) => c.slug), [
        'xqc',
        'xqcow-waiting-room-x',
        'xqc-pog',
      ]);
      expect(results[0].displayName, 'xQc');
      expect(results[0].verified, isTrue);
      expect(results[0].isLive, isFalse);
      expect(results[0].followersCount, 1118300);
      expect(results[1].isLive, isTrue);
      expect(results[1].verified, isFalse);
    });

    test('skips the request under 3 characters (Kick answers 400)', () async {
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        return http.Response(
          '{"message": "Please enter at least 3 characters"}',
          400,
        );
      });

      final results = await KickChannelService(
        client: client,
      ).searchChannels('xq');

      expect(results, isEmpty);
      expect(calls, 0);
    });

    test('a blocked / failed answer throws with its status', () async {
      final client = MockClient(
        (request) async => http.Response('blocked', 403),
      );

      expect(
        () => KickChannelService(client: client).searchChannels('xqc'),
        throwsA(
          isA<KickApiException>().having((e) => e.statusCode, 'status', 403),
        ),
      );
    });
  });
}
