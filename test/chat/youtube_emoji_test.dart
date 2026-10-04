import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/stores/views/youtube_emojis.dart';
import 'package:obs_blade/utils/youtube/youtube_emoji.dart';

/// Emoji objects as YouTube's web live chat sends them in message runs
/// (captured 2026-10-04 from public live chats; member emoji ids kept,
/// they're public).
Map<String, Object?> _standard(String id, String code) => {
  'emojiId': '$kYouTubeStandardEmojiOwner/$id',
  'shortcuts': [code],
  'searchTerms': [code.replaceAll(':', '')],
  'image': {
    'thumbnails': [
      {'url': 'https://yt3.ggpht.com/$id=w24-h24-c-k-nd', 'width': 24},
      {'url': 'https://yt3.ggpht.com/$id=w48-h48-c-k-nd', 'width': 48},
    ],
    'accessibility': {
      'accessibilityData': {'label': code},
    },
  },
  'isCustomEmoji': true,
};

const Map<String, Object?> _member = {
  'emojiId': 'UCHnGh6ClNwEy4aK-bnufo1w/qTvDZ-byDvjRi9oPyYCpwQQ',
  'shortcuts': [':_addiOmg:', ':addiOmg:', ':_omg:', ':omg:'],
  'searchTerms': ['_addiOmg', 'addiOmg', '_omg', 'omg'],
  'image': {
    'thumbnails': [
      {'url': 'https://yt3.ggpht.com/W9gw=w24-h24-c-k-nd', 'width': 24},
      {'url': 'https://yt3.ggpht.com/W9gw=w48-h48-c-k-nd', 'width': 48},
    ],
  },
  'isCustomEmoji': true,
};

/// Unicode emoji: no isCustomEmoji, a Noto image - the text has the char
const Map<String, Object?> _unicode = {
  'emojiId': '🎃',
  'shortcuts': [':jack_o_lantern:'],
  'image': {
    'thumbnails': [
      {'url': 'https://fonts.gstatic.com/s/e/notoemoji/15.1/1f383/72.png'},
    ],
  },
};

String _page(List<Map<String, Object?>> emojis) {
  final data = {
    'contents': {
      'liveChatRenderer': {
        'actions': [
          for (final emoji in emojis)
            {
              'addChatItemAction': {
                'item': {
                  'liveChatTextMessageRenderer': {
                    'message': {
                      'runs': [
                        {'text': 'Thanks Remy '},
                        {'emoji': emoji},
                      ],
                    },
                  },
                },
              },
            },
        ],
      },
    },
  };
  return '<html><script nonce="x">window["ytInitialData"] = '
      '${json.encode(data)};</script></html>';
}

void main() {
  group('page parser', () {
    test('standard and member emojis, unicode skipped, size suffix cut', () {
      final emojis = parseYouTubeEmojis(
        _page([_standard('medal1', ':zz-test-only-medal:'), _member, _unicode]),
      );
      expect(emojis, hasLength(2));
      final medal = emojis.firstWhere((e) => e.isStandard);
      expect(medal.code, ':zz-test-only-medal:');
      expect(medal.imageBase, 'https://yt3.ggpht.com/medal1');
      expect(medal.imageUrl(72), 'https://yt3.ggpht.com/medal1=w72-h72-c-k-nd');
      final member = emojis.firstWhere((e) => !e.isStandard);
      expect(member.ownerChannelId, 'UCHnGh6ClNwEy4aK-bnufo1w');
      expect(member.codes, contains(':omg:'));
    });

    test('a page without chat data (consent wall, layout change): none', () {
      expect(parseYouTubeEmojis('<html>nothing</html>'), isEmpty);
      expect(parseYouTubeEmojis('ytInitialData = {broken;</script>'), isEmpty);
    });
  });

  test('code pattern: codes next to each other, never clock times', () {
    List<String> codes(String text) => [
      for (final m in kYouTubeEmojiCodePattern.allMatches(text)) m.group(0)!,
    ];
    expect(codes('gg :yt::face-blue-smiling: wow'), [
      ':yt:',
      ':face-blue-smiling:',
    ]);
    expect(codes('starts at 10:30:45 and :_addiOmg:!'), [':_addiOmg:']);
    expect(codes('ratio 3:2'), isEmpty);
  });

  group('store', () {
    late DateTime now;
    late List<Uri> requests;
    late String body;
    late int status;
    late MemoryYouTubeEmojiPersistence persistence;

    YouTubeEmojiStore build() => YouTubeEmojiStore(
      client: MockClient((request) async {
        requests.add(request.url);
        return http.Response(body, status);
      }),
      clock: () => now,
      persistence: persistence,
    );

    setUp(() {
      now = DateTime.utc(2026, 10, 4, 12);
      requests = [];
      body = _page([_standard('medal1', ':zz-test-only-medal:'), _member]);
      status = 200;
      persistence = MemoryYouTubeEmojiPersistence();
    });

    test('bundled standard set is known without any read', () async {
      final store = build();
      await store.init();
      expect(store.standard, isNotEmpty);
      expect(store.lookup(store.standard.first.code), isNotNull);
      expect(requests, isEmpty);
    });

    test(
      'learn: reads the chat page once per 2 min, keeps what it finds',
      () async {
        final store = build();
        await store.init();
        await store.learn('vid1');
        expect(requests.single.path, '/live_chat');
        expect(requests.single.queryParameters['v'], 'vid1');
        expect(store.lookup(':zz-test-only-medal:'), isNotNull);
        expect(
          store
              .lookup(':omg:', channelId: 'UCHnGh6ClNwEy4aK-bnufo1w')
              ?.ownerChannelId,
          'UCHnGh6ClNwEy4aK-bnufo1w',
        );
        expect(store.membersOf('UCHnGh6ClNwEy4aK-bnufo1w'), hasLength(1));

        await store.learn('vid1');
        expect(requests, hasLength(1));
        now = now.add(const Duration(minutes: 3));
        await store.learn('vid1');
        expect(requests, hasLength(2));
      },
    );

    test('learned emojis survive a restart', () async {
      final first = build();
      await first.init();
      await first.learn('vid1');
      final second = build();
      await second.init();
      expect(
        second.lookup(':_addiOmg:', channelId: 'UCHnGh6ClNwEy4aK-bnufo1w'),
        isNotNull,
      );
    });

    test(
      'an unknown code triggers one read per burst; known codes none',
      () async {
        final store = build();
        await store.init();
        final known = store.standard.first.code;
        store.noteText('hi $known', videoId: 'vid1');
        await Future<void>.delayed(
          kYouTubeEmojiUnknownDebounce + const Duration(milliseconds: 50),
        );
        expect(requests, isEmpty);

        store.noteText('Thanks Remy :zz-test-only-medal:', videoId: 'vid1');
        store.noteText('again :zz-test-only-medal:', videoId: 'vid1');
        await Future<void>.delayed(
          kYouTubeEmojiUnknownDebounce + const Duration(milliseconds: 50),
        );
        expect(requests, hasLength(1));
        expect(store.lookup(':zz-test-only-medal:'), isNotNull);
        store.dispose();
      },
    );

    test('a failed read leaves codes as text and no crash', () async {
      status = 403;
      final store = build();
      await store.init();
      await store.learn('vid1');
      expect(store.lookup(':zz-test-only-medal:'), isNull);
    });

    test('recently used: newest first, persisted, capped', () async {
      final store = build();
      await store.init();
      final a = store.standard[0];
      final b = store.standard[1];
      store.used(a);
      store.used(b);
      store.used(a);
      expect(store.recent.map((e) => e.id), [a.id, b.id]);
      final again = build();
      await again.init();
      expect(again.recent.map((e) => e.id), [a.id, b.id]);
    });
  });

  group('review fixes', () {
    late List<Uri> requests;
    late String body;
    late DateTime now;

    YouTubeEmojiStore build() => YouTubeEmojiStore(
      client: MockClient((request) async {
        requests.add(request.url);
        return http.Response(body, 200);
      }),
      clock: () => now,
      persistence: MemoryYouTubeEmojiPersistence(),
    );

    setUp(() {
      requests = [];
      now = DateTime.utc(2026, 10, 4, 12);
      body = _page([_member]);
    });

    test('member codes resolve only in their own channel', () async {
      final store = build();
      await store.init();
      await store.learn('vid1');
      expect(
        store.lookup(':omg:', channelId: 'UCHnGh6ClNwEy4aK-bnufo1w'),
        isNotNull,
      );
      expect(store.lookup(':omg:', channelId: 'UCsomeoneelse'), isNull);
      expect(store.lookup(':omg:'), isNull);

      /// Standard codes resolve everywhere
      final standard = store.standard.first.code;
      expect(store.lookup(standard, channelId: 'UCsomeoneelse'), isNotNull);
    });

    test('a code the page never has stops triggering reads', () async {
      final store = build();
      await store.init();
      store.noteText('hand typed :skull:', videoId: 'vid1');
      await Future<void>.delayed(
        kYouTubeEmojiUnknownDebounce + const Duration(milliseconds: 50),
      );
      expect(requests, hasLength(1));

      now = now.add(const Duration(minutes: 10));
      store.noteText('again :skull:', videoId: 'vid1');
      await Future<void>.delayed(
        kYouTubeEmojiUnknownDebounce + const Duration(milliseconds: 50),
      );
      expect(requests, hasLength(1));
      store.dispose();
    });
  });
}
