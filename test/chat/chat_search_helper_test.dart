import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/utils/chat_search_helper.dart';

void main() {
  group('chatSearchMatches', () {
    test('matches content case-insensitively', () {
      expect(
        chatSearchMatches(
          query: 'GIVEAWAY',
          author: 'Viewer',
          content: 'check out my giveaway',
        ),
        isTrue,
      );
    });

    test('matches the author name', () {
      expect(
        chatSearchMatches(query: 'kounex', author: 'Kounex', content: 'hello'),
        isTrue,
      );
    });

    test('matches as a substring, not a whole word', () {
      expect(
        chatSearchMatches(
          query: 'give',
          author: 'Viewer',
          content: 'giveaway time',
        ),
        isTrue,
      );
    });

    test('no match when neither author nor content contains the query', () {
      expect(
        chatSearchMatches(
          query: 'giveaway',
          author: 'Viewer',
          content: 'just a regular message',
        ),
        isFalse,
      );
    });

    test('a blank/whitespace-only query never matches', () {
      expect(
        chatSearchMatches(query: '   ', author: 'Viewer', content: 'hello'),
        isFalse,
      );
    });

    test('trims surrounding whitespace from the query', () {
      expect(
        chatSearchMatches(
          query: '  giveaway  ',
          author: 'Viewer',
          content: 'my giveaway',
        ),
        isTrue,
      );
    });
  });
}
