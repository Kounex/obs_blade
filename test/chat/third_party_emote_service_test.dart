import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/utils/twitch/third_party_emote_service.dart';

/// Mirrors the verified 7TV v3 payload shape (see the design spec):
/// protocol-relative host URL; entries with a missing name/host are
/// skipped.
const _kSevenTvEmotesBody = {
  'emotes': [
    {
      'id': '01FCY771D800007PQ2DF3GDTN6',
      'name': 'RainTime',
      'data': {
        'host': {'url': '//cdn.7tv.app/emote/01FCY771D800007PQ2DF3GDTN6'},
        'animated': true,
      },
    },
    {
      'id': 'broken-no-host',
      'name': 'BrokenTime',
      'data': {},
    },
    {
      'id': 'broken-no-name',
      'data': {
        'host': {'url': '//cdn.7tv.app/emote/broken'},
      },
    },
  ],
};

void main() {
  group('fetchSevenTvGlobal', () {
    test('parses name + 2x webp url, skips malformed entries', () async {
      final client = MockClient((request) async {
        expect(
            request.url.toString(), 'https://7tv.io/v3/emote-sets/global');
        return http.Response(json.encode(_kSevenTvEmotesBody), 200);
      });

      final emotes =
          await ThirdPartyEmoteService(client: client).fetchSevenTvGlobal();

      expect(emotes, hasLength(1));
      expect(emotes['RainTime']?.imageUrl,
          'https://cdn.7tv.app/emote/01FCY771D800007PQ2DF3GDTN6/2x.webp');
    });
  });

  group('fetchSevenTvChannel', () {
    test('reads the active emote set', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(),
            'https://7tv.io/v3/users/twitch/user-1');
        return http.Response(
            json.encode({'emote_set': _kSevenTvEmotesBody}), 200);
      });

      final emotes = await ThirdPartyEmoteService(client: client)
          .fetchSevenTvChannel('user-1');

      expect(emotes['RainTime'], isNotNull);
    });

    test('no active emote set returns an empty map', () async {
      final client = MockClient((request) async =>
          http.Response(json.encode({'id': 'user-1'}), 200));

      final emotes = await ThirdPartyEmoteService(client: client)
          .fetchSevenTvChannel('user-1');

      expect(emotes, isEmpty);
    });

    test('404 returns an empty map (channel without 7TV presence)',
        () async {
      final client = MockClient((request) async => http.Response('', 404));

      final emotes = await ThirdPartyEmoteService(client: client)
          .fetchSevenTvChannel('user-1');

      expect(emotes, isEmpty);
    });

    test('other non-200 throws ThirdPartyEmoteException with status', () {
      final client =
          MockClient((request) async => http.Response('nope', 500));

      expect(
        ThirdPartyEmoteService(client: client).fetchSevenTvChannel('user-1'),
        throwsA(isA<ThirdPartyEmoteException>()
            .having((e) => e.statusCode, 'statusCode', 500)),
      );
    });
  });

  group('fetchBttvGlobal', () {
    test('parses the flat id/code array into cdn urls', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(),
            'https://api.betterttv.net/3/cached/emotes/global');
        return http.Response(
          json.encode([
            {
              'id': '54fa8f',
              'code': ':tf:',
              'imageType': 'png',
              'animated': false,
            },
            {
              'id': '55b6f4',
              'code': 'monkaS',
              'imageType': 'gif',
              'animated': true,
            },
            {'code': 'broken-no-id'},
          ]),
          200,
        );
      });

      final emotes =
          await ThirdPartyEmoteService(client: client).fetchBttvGlobal();

      expect(emotes, hasLength(2));
      expect(emotes['monkaS']?.imageUrl,
          'https://cdn.betterttv.net/emote/55b6f4/2x');
    });
  });

  group('fetchBttvChannel', () {
    test('merges channel + shared emotes, shared wins ties', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(),
            'https://api.betterttv.net/3/cached/users/twitch/user-1');
        return http.Response(
          json.encode({
            'channelEmotes': [
              {'id': 'chan1', 'code': 'xqcL', 'imageType': 'png'},
              {'id': 'tie-channel', 'code': 'TieEmote', 'imageType': 'png'},
            ],
            'sharedEmotes': [
              {'id': 'shared1', 'code': 'SourPls', 'imageType': 'gif'},
              {'id': 'tie-shared', 'code': 'TieEmote', 'imageType': 'gif'},
            ],
          }),
          200,
        );
      });

      final emotes = await ThirdPartyEmoteService(client: client)
          .fetchBttvChannel('user-1');

      expect(emotes, hasLength(3));
      expect(emotes['xqcL']?.imageUrl,
          'https://cdn.betterttv.net/emote/chan1/2x');
      expect(emotes['SourPls']?.imageUrl,
          'https://cdn.betterttv.net/emote/shared1/2x');
      expect(emotes['TieEmote']?.imageUrl,
          'https://cdn.betterttv.net/emote/tie-shared/2x');
    });

    test('404 returns an empty map (channel without BTTV presence)',
        () async {
      final client = MockClient((request) async => http.Response('', 404));

      final emotes = await ThirdPartyEmoteService(client: client)
          .fetchBttvChannel('user-1');

      expect(emotes, isEmpty);
    });

    test('other non-200 throws ThirdPartyEmoteException with status', () {
      final client = MockClient((request) async => http.Response('nope', 502));

      expect(
        ThirdPartyEmoteService(client: client).fetchBttvGlobal(),
        throwsA(isA<ThirdPartyEmoteException>()
            .having((e) => e.statusCode, 'statusCode', 502)),
      );
    });
  });
}
