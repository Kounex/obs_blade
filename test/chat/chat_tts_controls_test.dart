import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/pro_store.dart';
import 'package:obs_blade/stores/views/chat_tts.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/chat_tts/chat_tts_queue.dart';
import 'package:obs_blade/utils/chat_tts/chat_tts_utterance.dart';
import 'package:obs_blade/utils/chat_tts/chat_tts_voice.dart';
import 'package:obs_blade/utils/pro_purchase_service.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_tts_controls.dart';

import '../persistence/support/hive_test_harness.dart';
import '../pro/support/fake_pro_purchase_gateway.dart';

class _HangingSpeaker implements ChatTtsSpeaker {
  final List<String> spoken = [];
  final List<Completer<void>> _running = [];

  @override
  Future<void> speak(String text, {String? detectionText}) {
    spoken.add(text);
    final done = Completer<void>();
    _running.add(done);
    return done.future;
  }

  @override
  Future<void> stop() async {
    for (final running in _running) {
      if (!running.isCompleted) running.complete();
    }
    _running.clear();
  }
}

ChatTtsMessage _msg(String text) => ChatTtsMessage(
  id: text,
  platform: ChatType.Twitch,
  author: 'Viewer',
  authorNames: const ['Viewer'],
  parts: [ChatTtsPart.text(text)],
);

/// The header speaker: Pro only, tap toggles (first time with a one-off
/// hint), long press opens the settings, the waiting chip jumps ahead.
void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late ProStore proStore;
  late ChatTtsStore ttsStore;
  late _HangingSpeaker speaker;
  late StreamController<ChatTtsMessage> messages;

  Box<dynamic> settings() => Hive.box(HiveKeys.Settings.name);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('chat_tts_controls');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();
    await settings().put(SettingsKeys.ProColdStartRestoreDone.name, true);
    proStore = ProStore(
      service: ProPurchaseService(gateway: FakeProPurchaseGateway()),
    )..init();
    GetIt.instance.registerSingleton<ProStore>(proStore);

    speaker = _HangingSpeaker();
    messages = StreamController.broadcast();
    ttsStore = ChatTtsStore(
      speaker: speaker,
      isProResolver: () => proStore.isPro,
      messages: () => messages.stream,
      voicesLoader: () async => const [
        ChatTtsVoice(
          id: 'ava',
          name: 'Ava',
          language: 'en-US',
          languageName: 'English (United States)',
          quality: 3,
        ),
        ChatTtsVoice(
          id: 'anna',
          name: 'Anna',
          language: 'de-DE',
          languageName: 'German (Germany)',
          quality: 1,
        ),
      ],
    );
    GetIt.instance.registerSingleton<ChatTtsStore>(ttsStore);
  });

  tearDown(() async {
    ttsStore.dispose();
    await messages.close();
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Widget app() => MaterialApp(
    theme: ThemeData(
      brightness: Brightness.dark,
      cupertinoOverrideTheme: const CupertinoThemeData(),
      extensions: const [AppStatusColors.standard, AppTextColors.standard],
    ),
    home: const Scaffold(body: Center(child: ChatTtsButton())),
  );

  void setPro(bool pro) => runInAction(() => proStore.debugOverride = pro);

  testWidgets('hidden without Pro', (tester) async {
    setPro(false);
    await tester.pumpWidget(app());
    expect(find.byKey(const Key('chat-tts-button')), findsNothing);
  });

  /// Taps that persist (switch state, hint flag) write the settings box
  /// (real I/O) - run them in a real zone, never inside the fake clock
  Future<void> tapReal(WidgetTester tester, Finder finder) =>
      tester.runAsync(() async {
        await tester.tap(finder);
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });

  /// A dropdown reports a pick only after its menu's close animation, on
  /// the fake clock - the settings write would land in the fake zone and
  /// never finish. Pick through the dropdown's own callback in a real zone
  Future<void> pickLanguage(WidgetTester tester, String value) =>
      tester.runAsync(() async {
        tester
            .widget<DropdownButton<String>>(find.byType(DropdownButton<String>))
            .onChanged!(value);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });

  testWidgets('first switch-on: reading starts + the one-off hint', (
    tester,
  ) async {
    setPro(true);
    await tester.pumpWidget(app());

    await tapReal(tester, find.byKey(const Key('chat-tts-button')));

    /// The overlay was scheduled from the real zone (250ms delay)
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(ttsStore.enabled, isTrue);
    expect(find.textContaining('Hold the speaker'), findsOneWidget);
    expect(settings().get(SettingsKeys.HasUserSeenChatTtsHint.name), isTrue);

    /// Let the overlay run out
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('hint already seen: tap just toggles', (tester) async {
    setPro(true);
    await tester.runAsync(
      () => settings().put(SettingsKeys.HasUserSeenChatTtsHint.name, true),
    );
    await tester.pumpWidget(app());

    await tapReal(tester, find.byKey(const Key('chat-tts-button')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(ttsStore.enabled, isTrue);
    expect(find.textContaining('Hold the speaker'), findsNothing);

    await tapReal(tester, find.byKey(const Key('chat-tts-button')));
    await tester.pump();
    expect(ttsStore.enabled, isFalse);
  });

  testWidgets('long press opens the settings', (tester) async {
    setPro(true);
    await tester.pumpWidget(app());

    await tester.longPress(find.byKey(const Key('chat-tts-button')));
    await tester.pumpAndSettle();
    expect(find.text('Text to speech'), findsOneWidget);
    expect(find.text('Read chat aloud'), findsOneWidget);
    expect(find.text('Mentions only'), findsOneWidget);
    expect(ttsStore.enabled, isFalse);

    /// Language: a dropdown, phone language preselected, the voice it
    /// reads with underneath
    await tester.scrollUntilVisible(
      find.byKey(const Key('tts-language-dropdown')),
      200.0,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text("Detect each message's language"), findsOneWidget);
    expect(find.text('Phone language'), findsOneWidget);
    expect(find.textContaining('Voice: Ava'), findsOneWidget);
    expect(find.text('Volume'), findsOneWidget);

    /// The menu lists every installed language
    await tester.tap(find.byKey(const Key('tts-language-dropdown')));
    await tester.pumpAndSettle();
    expect(find.text('German (Germany)'), findsWidgets);
    expect(find.text('English (United States)'), findsWidgets);
    /// Dismiss via the barrier - no pick, no settings write
    await tester.tapAt(const Offset(4.0, 4.0));
    await tester.pumpAndSettle();

    /// Picking a language makes it the default (persisted)
    await pickLanguage(tester, 'de-DE');
    await tester.pumpAndSettle();
    expect(settings().get(SettingsKeys.ChatTtsLanguage.name), 'de-DE');
    expect(find.textContaining('Voice: Anna'), findsOneWidget);

    /// And back to the phone's language
    await pickLanguage(tester, '');
    await tester.pumpAndSettle();
    expect(settings().get(SettingsKeys.ChatTtsLanguage.name), isNull);
  });

  testWidgets('the waiting chip jumps to the latest message', (tester) async {
    setPro(true);
    await tester.runAsync(
      () => settings().put(SettingsKeys.HasUserSeenChatTtsHint.name, true),
    );
    await tester.pumpWidget(app());
    await tester.runAsync(() async {
      ttsStore.setEnabled(true);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    messages
      ..add(_msg('one'))
      ..add(_msg('two'))
      ..add(_msg('three'));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('chat-tts-waiting')), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('chat-tts-waiting')));
    await tester.pump();
    await tester.pump();
    expect(ttsStore.waiting, 0);
    expect(find.byKey(const Key('chat-tts-waiting')), findsNothing);
  });
}
