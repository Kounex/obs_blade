import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/utils/chat_highlight_helper.dart';

void main() {
  group('parseChatHighlightKeywords', () {
    test('splits on newlines and commas, trims whitespace', () {
      expect(parseChatHighlightKeywords('  foo\nbar , baz\n\nqux  '), [
        'foo',
        'bar',
        'baz',
        'qux',
      ]);
    });

    test('drops empty entries', () {
      expect(parseChatHighlightKeywords('foo,,  ,\nbar'), ['foo', 'bar']);
    });

    test('dedupes case-insensitively, keeping first occurrence', () {
      expect(parseChatHighlightKeywords('Foo, bar, FOO, BAR, baz'), [
        'Foo',
        'bar',
        'baz',
      ]);
    });

    test('empty string yields an empty list', () {
      expect(parseChatHighlightKeywords(''), isEmpty);
    });
  });

  group('chatContentIsHighlighted', () {
    test('matches a self name case-insensitively when enabled', () {
      expect(
        chatContentIsHighlighted(
          'hey KOUNEX, nice stream',
          selfMentionEnabled: true,
          selfNames: ['kounex'],
          keywords: const [],
        ),
        isTrue,
      );
    });

    test('does not match a self name when disabled', () {
      expect(
        chatContentIsHighlighted(
          'hey kounex, nice stream',
          selfMentionEnabled: false,
          selfNames: ['kounex'],
          keywords: const [],
        ),
        isFalse,
      );
    });

    test('ignores null/blank self names', () {
      expect(
        chatContentIsHighlighted(
          'hello world',
          selfMentionEnabled: true,
          selfNames: [null, '', '   '],
          keywords: const [],
        ),
        isFalse,
      );
    });

    test('matches a configured keyword regardless of self-mention toggle', () {
      expect(
        chatContentIsHighlighted(
          'anyone seen my GIVEAWAY post?',
          selfMentionEnabled: false,
          selfNames: const [],
          keywords: const ['giveaway'],
        ),
        isTrue,
      );
    });

    test('matches as a substring, not a whole word', () {
      expect(
        chatContentIsHighlighted(
          'kounexFan99 says hi',
          selfMentionEnabled: true,
          selfNames: ['kounex'],
          keywords: const [],
        ),
        isTrue,
      );
    });

    test('empty content never matches', () {
      expect(
        chatContentIsHighlighted(
          '',
          selfMentionEnabled: true,
          selfNames: ['kounex'],
          keywords: const ['kounex'],
        ),
        isFalse,
      );
    });

    test('no match when neither self names nor keywords are present', () {
      expect(
        chatContentIsHighlighted(
          'just a regular message',
          selfMentionEnabled: true,
          selfNames: ['kounex'],
          keywords: const ['giveaway'],
        ),
        isFalse,
      );
    });
  });
}
