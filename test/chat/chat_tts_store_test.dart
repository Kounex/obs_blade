import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/stores/views/chat_tts.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/chat_tts/chat_tts_queue.dart';
import 'package:obs_blade/utils/chat_tts/chat_tts_utterance.dart';

import '../persistence/support/hive_test_harness.dart';

class _FakeSpeaker implements ChatTtsSpeaker {
  final List<String> spoken = [];
  final List<String?> detectionTexts = [];
  final List<Completer<void>> _running = [];

  @override
  Future<void> speak(String text, {String? detectionText}) {
    spoken.add(text);
    detectionTexts.add(detectionText);
    final done = Completer<void>();
    _running.add(done);
    return done.future;
  }

  void finish() => _running.removeAt(0).complete();

  @override
  Future<void> stop() async {
    for (final running in _running) {
      if (!running.isCompleted) running.complete();
    }
    _running.clear();
  }
}

ChatTtsMessage _msg(
  String text, {
  String author = 'Viewer',
  bool mod = false,
}) => ChatTtsMessage(
  id: text,
  platform: ChatType.Twitch,
  author: author,
  authorNames: [author],
  parts: [ChatTtsPart.text(text)],
  isModerator: mod,
  selfNames: const ['Streamer'],
);

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late _FakeSpeaker speaker;
  late StreamController<ChatTtsMessage> messages;
  late bool isPro;
  late ChatTtsStore store;

  Box<dynamic> settings() => Hive.box(HiveKeys.Settings.name);

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('chat_tts_store');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();
    speaker = _FakeSpeaker();
    messages = StreamController.broadcast();
    isPro = true;
    store = ChatTtsStore(
      speaker: speaker,
      isProResolver: () => isPro,
      messages: () => messages.stream,
    );
  });

  tearDown(() async {
    store.dispose();
    await messages.close();
    await harness.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('off by default - nothing is read', () async {
    store.init();
    messages.add(_msg('hello'));
    await settle();
    expect(store.enabled, isFalse);
    expect(speaker.spoken, isEmpty);
  });

  test('on: reads live messages, persists the switch', () async {
    store.setEnabled(true);
    messages.add(_msg('hello'));
    await settle();
    expect(speaker.spoken, ['Viewer: hello']);
    expect(settings().get(SettingsKeys.ChatTtsEnabled.name), isTrue);
  });

  test('a persisted switch resumes on init', () async {
    await settings().put(SettingsKeys.ChatTtsEnabled.name, true);
    store.init();
    expect(store.enabled, isTrue);
    messages.add(_msg('back'));
    await settle();
    expect(speaker.spoken, ['Viewer: back']);
  });

  test('without Pro nothing is read', () async {
    isPro = false;
    store.setEnabled(true);
    messages.add(_msg('hello'));
    await settle();
    expect(speaker.spoken, isEmpty);
  });

  test('settings sheet options apply to the next message', () async {
    store.setEnabled(true);
    await settings().put(SettingsKeys.ChatTtsReadUsernames.name, false);
    await settings().put(
      SettingsKeys.ChatTtsAudience.name,
      ChatTtsAudience.highlightedAndMods.name,
    );
    messages.add(_msg('regular viewer'));
    messages.add(_msg('mod message', mod: true));
    await settle();
    expect(speaker.spoken, ['mod message']);
  });

  test('chat-wide ignored users are not read', () async {
    store.setEnabled(true);
    await settings().put(SettingsKeys.ChatIgnoredUsers.name, 'Troll');
    messages.add(_msg('hi', author: 'Troll'));
    messages.add(_msg('hi', author: 'Friend'));
    await settle();
    expect(speaker.spoken, ['Friend: hi']);
  });

  test('waiting count follows the queue, jump to latest empties it', () async {
    store.setEnabled(true);
    messages.add(_msg('one'));
    messages.add(_msg('two'));
    messages.add(_msg('three'));
    await settle();
    expect(store.speaking, isTrue);
    expect(store.waiting, 2);

    await store.jumpToLatest();
    expect(store.waiting, 0);
    expect(store.speaking, isFalse);
    expect(speaker.spoken, ['Viewer: one']);
  });

  test('switching off stops and stops listening', () async {
    store.setEnabled(true);
    messages.add(_msg('one'));
    await settle();
    store.setEnabled(false);
    messages.add(_msg('two'));
    await settle();
    expect(speaker.spoken, ['Viewer: one']);
    expect(settings().get(SettingsKeys.ChatTtsEnabled.name), isFalse);
  });

  test('language detection gets the message alone, not the username', () async {
    store.setEnabled(true);
    messages.add(_msg('hola amigos que tal', author: 'EnglishName'));
    await settle();
    expect(speaker.spoken, ['EnglishName: hola amigos que tal']);
    expect(speaker.detectionTexts, ['hola amigos que tal']);
  });

  test('identical waiting messages are combined (switchable)', () async {
    store.setEnabled(true);
    messages
      ..add(_msg('first'))
      ..add(_msg('KEKW', author: 'A'))
      ..add(_msg('KEKW', author: 'B'))
      ..add(_msg('KEKW', author: 'C'));
    await settle();
    speaker.finish();
    await settle();
    expect(speaker.spoken, ['Viewer: first', 'A and 2 others: KEKW']);

    speaker.finish();
    await settings().put(SettingsKeys.ChatTtsCombineRepeats.name, false);
    messages
      ..add(_msg('one'))
      ..add(_msg('W', author: 'A'))
      ..add(_msg('W', author: 'B'));
    await settle();
    speaker.finish();
    await settle();
    speaker.finish();
    await settle();
    expect(speaker.spoken.skip(2), ['Viewer: one', 'A: W', 'B: W']);
  });
}
