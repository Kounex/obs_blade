import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/enums/chat_engine.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/chat_engine_switch.dart';

import '../persistence/support/hive_test_harness.dart';

/// Fixed-width host: the switch sizes `double.infinity` inside the bar's
/// right column, so it needs a bounded width in isolation
Widget wrap(Widget child) => MaterialApp(
      theme: ThemeData(cupertinoOverrideTheme: const CupertinoThemeData()),
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(0.8)),
        child: Scaffold(
          body: Center(child: SizedBox(width: 280.0, child: child)),
        ),
      ),
    );

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;

  Box<dynamic> settingsBox() => Hive.box(HiveKeys.Settings.name);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('chat_engine_switch');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
  });

  tearDown(() async {
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('renders nothing for platforms without a native engine',
      (tester) async {
    await tester.pumpWidget(wrap(ChatEngineSwitch(
        settingsBox: settingsBox(), chatType: ChatType.YouTube)));
    expect(find.byType(CupertinoSlidingSegmentedControl<ChatEngine>),
        findsNothing);

    await tester.pumpWidget(wrap(ChatEngineSwitch(
        settingsBox: settingsBox(), chatType: ChatType.Owncast)));
    expect(find.byType(CupertinoSlidingSegmentedControl<ChatEngine>),
        findsNothing);
  });

  testWidgets('Twitch shows both segments', (tester) async {
    await tester.pumpWidget(wrap(ChatEngineSwitch(
        settingsBox: settingsBox(), chatType: ChatType.Twitch)));

    expect(find.byType(CupertinoSlidingSegmentedControl<ChatEngine>),
        findsOneWidget);
    expect(find.text('WebView'), findsOneWidget);
    expect(find.text('Native'), findsOneWidget);
  });

  testWidgets('tapping a segment persists the engine', (tester) async {
    await tester.pumpWidget(wrap(ChatEngineSwitch(
        settingsBox: settingsBox(), chatType: ChatType.Twitch)));

    await tester.tap(find.text('Native'));
    await tester.pump();
    expect(settingsBox().get(SettingsKeys.SelectedChatEngine.name),
        ChatEngine.native);

    await tester.pumpWidget(wrap(ChatEngineSwitch(
        settingsBox: settingsBox(), chatType: ChatType.Twitch)));
    await tester.tap(find.text('WebView'));
    await tester.pump();
    expect(settingsBox().get(SettingsKeys.SelectedChatEngine.name),
        ChatEngine.webView);

    /// The taps ran their Hive writes in the test's FakeAsync zone, and
    /// the Completers Hive created for its write queue only dispatch
    /// their listeners through the zone they were created in - a
    /// real-zone harness.close() in tearDown would await one of them
    /// forever (proven: even 8 pump/runAsync drain rounds leave it
    /// stuck). So close Hive from inside the zone instead: each pump
    /// drains the zone's queue, each runAsync is a real-time window for
    /// the next file op of the close (handles close sequentially - hence
    /// several rounds). tearDown's harness.close() is then a no-op.
    /// Same dance as the 'connect button starts the login' integration
    /// test.
    var closed = false;
    unawaited(harness.close().then((_) => closed = true));
    for (var i = 0; i < 10 && !closed; i++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
    }
    await tester.pump();
    expect(closed, isTrue);
  });
}
