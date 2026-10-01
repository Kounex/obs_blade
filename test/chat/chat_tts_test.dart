import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
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
  Future<void> speak(String text) {
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
      final text = List.filled(60, 'word').join(' ');
      final said = _say(
        _msg(text),
        settings: const ChatTtsSettings(readUsernames: false, maxLength: 30),
      )!;
      expect(said.length, lessThanOrEqualTo(30));
      expect(said.endsWith('word'), isTrue);
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
}
