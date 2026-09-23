import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/utils/chat_mute_helper.dart';

void main() {
  group('chatContentIsMuted', () {
    test('matches a mute word case-insensitively', () {
      expect(chatContentIsMuted('check out my GIVEAWAY', ['giveaway']), isTrue);
    });

    test('matches as a substring, not a whole word', () {
      expect(chatContentIsMuted('freegiveawaynow', ['giveaway']), isTrue);
    });

    test('no match when content contains none of the mute words', () {
      expect(
        chatContentIsMuted('just a regular message', ['giveaway', 'scam']),
        isFalse,
      );
    });

    test('empty content never matches', () {
      expect(chatContentIsMuted('', ['giveaway']), isFalse);
    });

    test('empty mute word list never matches', () {
      expect(chatContentIsMuted('anything at all', const []), isFalse);
    });
  });

  group('censorChatContent', () {
    test('replaces every match case-insensitively', () {
      expect(
        censorChatContent('Spoiler: the SPOILER ends', ['spoiler']),
        '***: the *** ends',
      );
    });

    test('regex entries censor their match only', () {
      expect(
        censorChatContent('boss dies at 3:00', [r'/\d+:\d+/']),
        'boss dies at ***',
      );
    });

    test('regex metacharacters in plain words are literal', () {
      expect(censorChatContent('a.b axb', ['a.b']), '*** axb');
    });

    test('no words, no change', () {
      expect(censorChatContent('hello', const []), 'hello');
    });
  });
}
