import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/utils/chat_tts/chat_tts_combine.dart';
import 'package:obs_blade/utils/chat_tts/chat_tts_phrases.dart';
import 'package:obs_blade/utils/chat_tts/chat_tts_queue.dart';
import 'package:obs_blade/utils/chat_tts/chat_tts_utterance.dart';
import 'package:obs_blade/utils/chat_tts/chat_tts_voice.dart';

ChatTtsMessage _msg(
  String text, {
  String author = 'Viewer',
  List<ChatTtsPart>? parts,
  bool mod = false,
  bool broadcaster = false,
  bool own = false,
  List<String?> selfNames = const ['Streamer'],
  bool Function(String)? thirdParty,
}) => ChatTtsMessage(
  id: 'id',
  platform: ChatType.Twitch,
  author: author,
  authorNames: [author.toLowerCase(), author],
  parts: parts ?? [ChatTtsPart.text(text)],
  isModerator: mod,
  isBroadcaster: broadcaster,
  isOwn: own,
  selfNames: selfNames,
  isThirdPartyEmote: thirdParty,
);

String? _say(
  ChatTtsMessage message, {
  ChatTtsSettings settings = const ChatTtsSettings(),
  ChatTtsFilters filters = const ChatTtsFilters(),
}) => chatTtsUtterance(message, settings, filters);

class _FakeSpeaker implements ChatTtsSpeaker {
  final List<String> spoken = [];
  final List<Completer<void>> _running = [];
  int stops = 0;

  @override
  Future<void> speak(String text, {String? detectionText}) {
    spoken.add(text);
    final done = Completer<void>();
    _running.add(done);
    return done.future;
  }

  /// Finish the utterance currently being read
  void finish() => _running.removeAt(0).complete();

  @override
  Future<void> stop() async {
    stops++;
    for (final running in _running) {
      if (!running.isCompleted) running.complete();
    }
    _running.clear();
  }
}

void main() {
  group('chatTtsUtterance', () {
    test('reads author + text by default', () {
      expect(_say(_msg('hello there')), 'Viewer: hello there');
    });

    test('username can be left out', () {
      expect(
        _say(
          _msg('hello'),
          settings: const ChatTtsSettings(readUsernames: false),
        ),
        'hello',
      );
    });

    test('own messages are skipped unless enabled', () {
      expect(_say(_msg('mine', own: true)), isNull);
      expect(
        _say(
          _msg('mine', own: true),
          settings: const ChatTtsSettings(readOwnMessages: true),
        ),
        'Viewer: mine',
      );
    });

    test('!commands are skipped unless disabled', () {
      expect(_say(_msg('  !discord')), isNull);
      expect(
        _say(
          _msg('!discord'),
          settings: const ChatTtsSettings(skipCommands: false),
        ),
        'Viewer: !discord',
      );
    });

    test('emotes (first-party, third-party, shortcodes) are dropped', () {
      final message = _msg(
        '',
        parts: const [
          ChatTtsPart.text('nice '),
          ChatTtsPart.emote('Kappa'),
          ChatTtsPart.text(' play OMEGALUL :hand-pink-waving: gg'),
        ],
        thirdParty: (word) => word == 'OMEGALUL',
      );
      expect(_say(message), 'Viewer: nice play gg');
      expect(
        _say(message, settings: const ChatTtsSettings(skipEmotes: false)),
        'Viewer: nice Kappa play OMEGALUL :hand-pink-waving: gg',
      );
    });

    test('emote-only messages say nothing', () {
      final message = _msg('', parts: const [ChatTtsPart.emote('PogChamp')]);
      expect(_say(message), isNull);
    });

    test('links are dropped', () {
      expect(
        _say(_msg('look https://example.com/x and www.foo.bar and clips.tv/a')),
        'Viewer: look and and',
      );
      expect(
        _say(
          _msg('see https://example.com'),
          settings: const ChatTtsSettings(skipLinks: false),
        ),
        'Viewer: see https://example.com',
      );
    });

    test('spam runs collapse to three', () {
      expect(_say(_msg('noooooooo!!!!!!')), 'Viewer: nooo!!!');
    });

    test('long messages are cut at a word boundary', () {
      /// Distinct words - identical ones would collapse into "word 60 times"
      final text = List.generate(60, (i) => 'word$i').join(' ');
      final said = _say(
        _msg(text),
        settings: const ChatTtsSettings(readUsernames: false, maxLength: 30),
      )!;
      expect(said.length, lessThanOrEqualTo(30));
      expect(said, matches(RegExp(r'word\d+$')));
      expect(text.startsWith('$said '), isTrue);
      expect(
        _say(
          _msg(text),
          settings: const ChatTtsSettings(readUsernames: false, maxLength: 0),
        ),
        text,
      );
    });

    test('ignored users and mute words follow the timeline rules', () {
      expect(
        _say(
          _msg('hi', author: 'Troll'),
          filters: const ChatTtsFilters(ignoredUsers: {'troll'}),
        ),
        isNull,
      );
      expect(
        _say(
          _msg('some spoiler here'),
          filters: const ChatTtsFilters(muteWords: ['spoiler']),
        ),
        isNull,
      );

      /// Censor mode keeps the row - TTS leaves the match out
      expect(
        _say(
          _msg('some spoiler here'),
          filters: const ChatTtsFilters(
            muteWords: ['spoiler'],
            muteReplace: true,
          ),
        ),
        'Viewer: some here',
      );
    });

    group('audience', () {
      const highlighted = ChatTtsSettings(
        audience: ChatTtsAudience.highlightedAndMods,
      );
      const mentions = ChatTtsSettings(audience: ChatTtsAudience.mentions);

      test('highlighted + mods: mods, broadcaster, listed users, mentions', () {
        expect(_say(_msg('hi'), settings: highlighted), isNull);
        expect(_say(_msg('hi', mod: true), settings: highlighted), isNotNull);
        expect(
          _say(_msg('hi', broadcaster: true), settings: highlighted),
          isNotNull,
        );
        expect(
          _say(
            _msg('hi', author: 'Friend'),
            settings: highlighted,
            filters: const ChatTtsFilters(highlightUsers: {'friend'}),
          ),
          isNotNull,
        );
        expect(_say(_msg('hey streamer'), settings: highlighted), isNotNull);
      });

      test('mentions: own name or highlight keyword only', () {
        expect(_say(_msg('hi', mod: true), settings: mentions), isNull);
        expect(_say(_msg('yo @Streamer'), settings: mentions), isNotNull);
        expect(
          _say(
            _msg('giveaway time'),
            settings: mentions,
            filters: const ChatTtsFilters(keywords: ['giveaway']),
          ),
          isNotNull,
        );
        expect(
          _say(
            _msg('yo @Streamer'),
            settings: mentions,
            filters: const ChatTtsFilters(selfMentionEnabled: false),
          ),
          isNull,
        );
      });
    });
  });

  group('ChatTtsQueue', () {
    late _FakeSpeaker speaker;
    late DateTime now;
    late ChatTtsQueue queue;

    setUp(() {
      speaker = _FakeSpeaker();
      now = DateTime(2026, 10, 1, 20);
      queue = ChatTtsQueue(speaker, now: () => now);
    });

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    test('reads one after another, counting the waiting ones', () async {
      queue.add('one');
      queue.add('two');
      queue.add('three');
      await settle();
      expect(speaker.spoken, ['one']);
      expect(queue.waiting, 2);
      expect(queue.speaking, isTrue);

      speaker.finish();
      await settle();
      expect(speaker.spoken, ['one', 'two']);
      expect(queue.waiting, 1);

      speaker.finish();
      await settle();
      speaker.finish();
      await settle();
      expect(speaker.spoken, ['one', 'two', 'three']);
      expect(queue.waiting, 0);
      expect(queue.speaking, isFalse);
    });

    test('nothing is skipped by default, however old', () async {
      queue.add('one');
      queue.add('old');
      await settle();
      now = now.add(const Duration(minutes: 5));
      speaker.finish();
      await settle();
      expect(speaker.spoken, ['one', 'old']);
    });

    test('opt-in stale skip drops messages older than the limit', () async {
      queue.skipStaleAfter = const Duration(seconds: 15);
      queue.add('one');
      queue.add('old', receivedAt: now);
      await settle();
      now = now.add(const Duration(seconds: 20));
      queue.add('fresh', receivedAt: now);
      speaker.finish();
      await settle();
      expect(speaker.spoken, ['one', 'fresh']);
    });

    test('jump to latest stops reading and empties the queue', () async {
      queue.add('one');
      queue.add('two');
      queue.add('three');
      await settle();

      await queue.clear();
      await settle();
      expect(speaker.stops, 1);
      expect(queue.waiting, 0);
      expect(queue.speaking, isFalse);
      expect(speaker.spoken, ['one']);

      queue.add('next');
      await settle();
      expect(speaker.spoken, ['one', 'next']);
    });

    test('a message that never reports "finished" times out, reading '
        'goes on', () async {
      queue = ChatTtsQueue(
        speaker,
        now: () => now,
        utteranceTimeout: (_) => const Duration(milliseconds: 30),
      );
      queue.add('stuck');
      queue.add('next');
      await settle();
      expect(speaker.spoken, ['stuck']);

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(speaker.stops, greaterThanOrEqualTo(1));
      expect(speaker.spoken, ['stuck', 'next']);
    });

    test('the default timeout grows with the text', () {
      expect(
        ChatTtsQueue.defaultUtteranceTimeout('x' * 200),
        greaterThan(ChatTtsQueue.defaultUtteranceTimeout('hi')),
      );
      expect(
        ChatTtsQueue.defaultUtteranceTimeout('x' * 150),
        greaterThanOrEqualTo(const Duration(seconds: 30)),
      );
    });

    test('notifies on every change', () async {
      var changes = 0;
      queue = ChatTtsQueue(speaker, now: () => now, onChanged: () => changes++);
      queue.add('one');
      await settle();
      expect(changes, greaterThan(0));
    });
  });

  group('chatTtsLanguages', () {
    ChatTtsVoice voice(
      String id,
      String language,
      int quality, {
      bool network = false,
    }) => ChatTtsVoice(
      id: id,
      name: id,
      language: language,
      languageName: language == 'de-DE' ? 'German (Germany)' : 'English (US)',
      quality: quality,
      network: network,
    );

    test('one row per language, best voice first, sorted by name', () {
      final languages = chatTtsLanguages([
        voice('Samantha', 'en-US', 1),
        voice('Ava', 'en-US', 3),
        voice('Anna', 'de-DE', 2),
      ]);
      expect(languages.map((l) => l.languageName), [
        'English (US)',
        'German (Germany)',
      ]);
      expect(languages.first.best.name, 'Ava');
      expect(languages.first.voiceCount, 2);
    });

    test('Android quality scale; offline wins a tie', () {
      final languages = chatTtsLanguages([
        voice('net-high', 'en-US', 400, network: true),
        voice('local-high', 'en-US', 500),
        voice('local-low', 'en-US', 200),
      ]);
      expect(languages.single.best.name, 'local-high');
      expect(voice('a', 'en-US', 300).qualityRank, 1);
      expect(voice('a', 'en-US', 3).qualityRank, 2);
      expect(voice('a', 'en-US', 1).qualityRank, 0);
    });
  });

  group('spam shortening', () {
    test('3+ identical words in a row are read once with a count', () {
      expect(
        _say(
          _msg('KEKW kekw KEKW KEKW gg no no'),
          settings: const ChatTtsSettings(readUsernames: false),
        ),
        'KEKW 4 times gg no no',
      );
    });

    test('the count follows the reading language', () {
      expect(
        _say(
          _msg('W W W'),
          settings: ChatTtsSettings(
            readUsernames: false,
            phrases: ChatTtsPhrases.of('de-DE'),
          ),
        ),
        'W 3 mal',
      );
    });

    test('emote runs collapse too while emotes are read', () {
      final message = _msg(
        '',
        parts: const [
          ChatTtsPart.emote('Kappa'),
          ChatTtsPart.text(' '),
          ChatTtsPart.emote('Kappa'),
          ChatTtsPart.text(' '),
          ChatTtsPart.emote('Kappa'),
        ],
      );
      expect(
        _say(
          message,
          settings: const ChatTtsSettings(
            readUsernames: false,
            skipEmotes: false,
          ),
        ),
        'Kappa 3 times',
      );
    });

    test('skip emote-only messages: only when nothing but emotes', () {
      const settings = ChatTtsSettings(
        readUsernames: false,
        skipEmotes: false,
        skipEmoteOnly: true,
      );
      final emoteOnly = _msg(
        '',
        parts: const [
          ChatTtsPart.emote('Kappa'),
          ChatTtsPart.text(' OMEGALUL :hand-pink-waving:'),
        ],
        thirdParty: (word) => word == 'OMEGALUL',
      );
      expect(_say(emoteOnly, settings: settings), isNull);
      final mixed = _msg(
        '',
        parts: const [ChatTtsPart.emote('Kappa'), ChatTtsPart.text(' nice')],
      );
      expect(_say(mixed, settings: settings), 'Kappa nice');
    });

    test('combine key: short messages only, counted after the collapse', () {
      ChatTtsSpoken? spoken(String text) => chatTtsSpoken(
        _msg(text),
        const ChatTtsSettings(),
        const ChatTtsFilters(),
      );
      expect(spoken('KEKW')!.combineKey, 'kekw');
      expect(spoken('KEKW KEKW KEKW KEKW KEKW')!.combineKey, isNotNull);
      expect(spoken('this is a longer message')!.combineKey, isNull);
    });

    test('notable: mods, the streamer and highlighted users', () {
      ChatTtsSpoken? spoken(ChatTtsMessage message) => chatTtsSpoken(
        message,
        const ChatTtsSettings(),
        const ChatTtsFilters(highlightUsers: {'friend'}),
      );
      expect(spoken(_msg('hi'))!.notable, isFalse);
      expect(spoken(_msg('hi', mod: true))!.notable, isTrue);
      expect(spoken(_msg('hi', broadcaster: true))!.notable, isTrue);
      expect(spoken(_msg('hi', author: 'Friend'))!.notable, isTrue);
    });
  });

  group('ChatTtsPhrases', () {
    test('by base language, English fallback', () {
      expect(ChatTtsPhrases.of('pt-BR').times(2), '2 vezes');
      expect(ChatTtsPhrases.of('zh-Hans').times(3), '3次');
      expect(ChatTtsPhrases.of('xx-YY').times(2), '2 times');
      expect(ChatTtsPhrases.of(null).times(2), '2 times');
    });

    test('names', () {
      const en = ChatTtsPhrases.english;
      expect(en.names(['A'], 0), 'A');
      expect(en.names(['A', 'B'], 0), 'A and B');
      expect(en.names(['A', 'B', 'C'], 0), 'A, B and C');
      expect(en.names(['A'], 1), 'A and one other');
      expect(en.names(['A', 'B'], 13), 'A, B and 13 others');
    });
  });

  group('chatTtsCombinedLine', () {
    ChatTtsQueueItem item(String author, {bool notable = false}) =>
        ChatTtsQueueItem(
          text: '$author: KEKW',
          detectionText: 'KEKW',
          receivedAt: DateTime(2026),
          combineKey: 'kekw',
          author: author,
          notable: notable,
        );

    test('usernames off: the message and how often', () {
      expect(
        chatTtsCombinedLine(
          [item('A'), item('B'), item('C')],
          readUsernames: false,
          phrases: ChatTtsPhrases.english,
        ),
        'KEKW 3 times',
      );
    });

    test('one person repeating', () {
      expect(
        chatTtsCombinedLine(
          [item('A'), item('A'), item('A')],
          readUsernames: true,
          phrases: ChatTtsPhrases.english,
        ),
        'A: KEKW 3 times',
      );
    });

    test('first author + notable people by name, the rest counted', () {
      expect(
        chatTtsCombinedLine(
          [
            item('First'),
            item('x1'),
            item('Mod', notable: true),
            item('x2'),
            item('x1'),
          ],
          readUsernames: true,
          phrases: ChatTtsPhrases.english,
        ),
        'First, Mod and 2 others: KEKW',
      );
    });

    test('at most three names', () {
      expect(
        chatTtsCombinedLine(
          [
            item('First'),
            item('M1', notable: true),
            item('M2', notable: true),
            item('M3', notable: true),
          ],
          readUsernames: true,
          phrases: ChatTtsPhrases.of('de'),
        ),
        'First, M1, M2 und eine weitere Person: KEKW',
      );
    });
  });

  group('ChatTtsQueue combining', () {
    late _FakeSpeaker speaker;
    late ChatTtsQueue queue;

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    setUp(() {
      speaker = _FakeSpeaker();
      queue = ChatTtsQueue(speaker)
        ..combine = (group) => '${group.length}x ${group.first.combineKey}';
    });

    void add(String text, {String? key}) =>
        queue.add(text, combineKey: key, author: text);

    test(
      'waiting identical messages are read once, others keep their turn',
      () async {
        add('first');
        add('kekw a', key: 'kekw');
        add('other');
        add('kekw b', key: 'kekw');
        add('kekw c', key: 'kekw');
        await settle();
        expect(speaker.spoken, ['first']);
        expect(queue.waiting, 4);

        speaker.finish();
        await settle();
        expect(speaker.spoken, ['first', '3x kekw']);
        expect(queue.waiting, 1);

        speaker.finish();
        await settle();
        expect(speaker.spoken, ['first', '3x kekw', 'other']);
      },
    );

    test('nothing is held back: a lone message reads as is', () async {
      add('kekw a', key: 'kekw');
      await settle();
      expect(speaker.spoken, ['kekw a']);

      /// Arrives while the first is read - combined with nothing waiting
      add('kekw b', key: 'kekw');
      speaker.finish();
      await settle();
      expect(speaker.spoken, ['kekw a', 'kekw b']);
    });

    test('switched off: every message reads on its own', () async {
      queue.combine = null;
      add('first');
      add('kekw a', key: 'kekw');
      add('kekw b', key: 'kekw');
      await settle();
      speaker.finish();
      await settle();
      speaker.finish();
      await settle();
      expect(speaker.spoken, ['first', 'kekw a', 'kekw b']);
    });
  });
}
