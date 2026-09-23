import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/utils/chat_autocomplete.dart';

ChatCompletionCandidate _emote(String name) =>
    ChatCompletionCandidate(label: name, insertText: name);

void main() {
  group('chatCompletionQueryAt', () {
    test('@ triggers a mention query, even with an empty prefix', () {
      final q = chatCompletionQueryAt('hi @', 4)!;
      expect(q.kind, ChatCompletionKind.mention);
      expect(q.prefix, '');
      expect((q.start, q.end), (3, 4));

      expect(chatCompletionQueryAt('hi @kou', 7)!.prefix, 'kou');
    });

    test(': triggers an emote query from 2 chars', () {
      expect(chatCompletionQueryAt(':k', 2), isNull);
      final q = chatCompletionQueryAt('lol :ka', 7)!;
      expect(q.kind, ChatCompletionKind.emote);
      expect(q.prefix, 'ka');
      expect(q.explicit, isTrue);
    });

    test('bare words need 3 chars and are not explicit', () {
      expect(chatCompletionQueryAt('ok', 2), isNull);
      final q = chatCompletionQueryAt('so Kap', 6)!;
      expect(q.prefix, 'Kap');
      expect(q.explicit, isFalse);
    });

    test('only at a word end', () {
      expect(chatCompletionQueryAt('Kappa hi', 3), isNull);
      expect(chatCompletionQueryAt('Kap hi', 3), isNotNull);
    });

    test('emails, urls and double triggers are ignored', () {
      expect(chatCompletionQueryAt('me@home', 7), isNull);
      expect(chatCompletionQueryAt('@a@b', 4), isNull);
      expect(chatCompletionQueryAt('a:b:c', 5), isNull);
      expect(chatCompletionQueryAt('', 0), isNull);
    });
  });

  group('rankChatCompletions', () {
    final pool = [
      _emote('KEKW'),
      _emote('Kappa'),
      _emote('kappaPride'),
      _emote('LUL'),
      _emote('OMEGALUL'),
    ];

    test('exact-case prefix, then case-insensitive prefix, then substring', () {
      expect(rankChatCompletions('Ka', pool).map((c) => c.label), [
        'Kappa',
        'kappaPride',
      ]);
      expect(rankChatCompletions('lul', pool).map((c) => c.label), [
        'LUL',
        'OMEGALUL',
      ]);
    });

    test('bare-word queries skip substring matches', () {
      expect(
        rankChatCompletions(
          'lul',
          pool,
          allowSubstring: false,
        ).map((c) => c.label),
        ['LUL'],
      );
    });

    test('a lone exact match has nothing left to complete', () {
      expect(rankChatCompletions('KEKW', pool), isEmpty);
    });

    test('dedupes by label and caps', () {
      final many = [
        for (var i = 0; i < 20; i++) _emote('pog$i'),
        _emote('pog0'),
      ];
      expect(rankChatCompletions('pog', many, limit: 5), hasLength(5));
      expect(
        rankChatCompletions('pog0', [
          _emote('pog0'),
          _emote('pog0x'),
        ]).map((c) => c.label),
        ['pog0', 'pog0x'],
      );
    });
  });

  group('applyChatCompletion', () {
    test('replaces the word and adds a space', () {
      final q = chatCompletionQueryAt('hi @kou', 7)!;
      final r = applyChatCompletion(
        'hi @kou',
        q,
        const ChatCompletionCandidate(label: 'Kounex', insertText: '@Kounex'),
      );
      expect(r.text, 'hi @Kounex ');
      expect(r.cursor, r.text.length);
    });

    test('reuses a following space', () {
      final q = chatCompletionQueryAt(':kap nice', 4)!;
      final r = applyChatCompletion(':kap nice', q, _emote('Kappa'));
      expect(r.text, 'Kappa nice');
      expect(r.cursor, 6);
    });
  });

  group('chatMentionCandidates', () {
    test('most recent first, deduped, self excluded', () {
      final c = chatMentionCandidates([
        ('alice', 'Alice'),
        ('kounex', 'Kounex'),
        ('bob', 'Bob'),
        ('alice', 'Alice'),
      ], selfLogin: 'Kounex');
      expect(c.map((e) => e.insertText), ['@Alice', '@Bob']);
    });

    test('non-latin display names fall back to the login', () {
      final c = chatMentionCandidates([('tanaka_1', '田中')]);
      expect(c.single.insertText, '@tanaka_1');
    });

    test('YouTube @handles are not double-prefixed', () {
      final c = chatMentionCandidates([('@Streamer', '@Streamer')]);
      expect(c.single.insertText, '@Streamer');
      expect(c.single.label, 'Streamer');
    });
  });
}
