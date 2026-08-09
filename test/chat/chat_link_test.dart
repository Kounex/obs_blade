import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_link.dart';

void main() {
  group('chatUrlMatches', () {
    test('finds http(s) URLs in a message', () {
      const text = 'see https://example.com/path and http://foo.bar/x.';
      final matches =
          chatUrlMatches(text).map((m) => m.group(0)).toList();
      expect(matches, [
        'https://example.com/path',
        'http://foo.bar/x.',
      ]);
    });

    test('finds bare domains and www hosts', () {
      const text =
          'try shorturl.at/xyz or www.example.com/a and twitch.tv/foo';
      final matches =
          chatUrlMatches(text).map((m) => m.group(0)).toList();
      expect(matches, [
        'shorturl.at/xyz',
        'www.example.com/a',
        'twitch.tv/foo',
      ]);
    });

    test('skips common file extensions and non-domain noise', () {
      expect(chatUrlMatches('photo.jpg'), isEmpty);
      expect(chatUrlMatches('notes.txt'), isEmpty);
      expect(chatUrlMatches('clip.mp4'), isEmpty);
      expect(chatUrlMatches('hello.'), isEmpty);
      expect(chatUrlMatches('i.e.'), isEmpty);
      expect(chatUrlMatches('user@example.com'), isEmpty);
    });
  });

  group('normalizeChatLinkUrl', () {
    test('keeps http(s) and strips trailing punctuation', () {
      expect(
        normalizeChatLinkUrl('https://example.com/path.'),
        'https://example.com/path',
      );
      expect(
        normalizeChatLinkUrl('http://foo.bar/x!'),
        'http://foo.bar/x',
      );
    });

    test('prepends https for bare domains and www', () {
      expect(
        normalizeChatLinkUrl('shorturl.at/xyz'),
        'https://shorturl.at/xyz',
      );
      expect(
        normalizeChatLinkUrl('www.example.com'),
        'https://www.example.com',
      );
    });

    test('returns null for unusable input', () {
      expect(normalizeChatLinkUrl('not a url'), isNull);
      expect(normalizeChatLinkUrl('ftp://example.com'), isNull);
    });
  });
}
