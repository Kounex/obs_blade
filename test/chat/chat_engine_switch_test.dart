import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/enums/chat_engine.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/stores/pro_store.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/icons/jam_icons.dart';
import 'package:obs_blade/utils/pro_purchase_service.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/chat_engine_switch.dart';

import '../persistence/support/hive_test_harness.dart';
import '../pro/support/fake_pro_purchase_gateway.dart';

/// Fixed-width host: the switch sizes `double.infinity` inside the bar's
/// right column, so it needs a bounded width in isolation.
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
  late ProStore proStore;

  Box<dynamic> settingsBox() => Hive.box(HiveKeys.Settings.name);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('chat_engine_switch');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);

    /// Entitlement: native engines are Pro-gated, so seed the real flag
    /// (the gate widgets read it through [ProStore.isPro]) and skip the
    /// cold-start restore. Native-mode tests run as Pro.
    await settingsBox().put(SettingsKeys.BoughtPro.name, true);
    await settingsBox()
        .put(SettingsKeys.ProColdStartRestoreDone.name, true);

    proStore = ProStore(
      service: ProPurchaseService(gateway: FakeProPurchaseGateway()),
    )..init();
    GetIt.instance.registerSingleton<ProStore>(proStore);
  });

  tearDown(() async {
    proStore.dispose();
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  /// Flip the entitlement off through the real box write - the store's
  /// watcher picks it up, the next pump rebuilds the Observer
  Future<void> revokePro(WidgetTester tester) async {
    await tester
        .runAsync(() => settingsBox().put(SettingsKeys.BoughtPro.name, false));
    await tester.pump();
  }

  testWidgets('renders nothing for platforms without a native engine',
      (tester) async {
    await tester.pumpWidget(wrap(ChatEngineSwitch(
        settingsBox: settingsBox(), chatType: ChatType.Owncast)));
    expect(find.byType(CupertinoSlidingSegmentedControl<ChatEngine>),
        findsNothing);
  });

  testWidgets('Twitch and YouTube show both segments', (tester) async {
    for (final chatType in [ChatType.Twitch, ChatType.YouTube]) {
      await tester.pumpWidget(wrap(ChatEngineSwitch(
          settingsBox: settingsBox(), chatType: chatType)));

      expect(find.byType(CupertinoSlidingSegmentedControl<ChatEngine>),
          findsOneWidget);
      expect(find.text('WebView'), findsOneWidget);
      expect(find.text('Native'), findsOneWidget);
    }
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

  testWidgets('Pro users see no lock badge on the Native segment',
      (tester) async {
    await tester.pumpWidget(wrap(ChatEngineSwitch(
        settingsBox: settingsBox(), chatType: ChatType.Twitch)));

    expect(find.byIcon(JamIcons.padlock), findsNothing);
  });

  testWidgets('not-Pro shows a lock badge on the Native segment',
      (tester) async {
    await tester.pumpWidget(wrap(ChatEngineSwitch(
        settingsBox: settingsBox(), chatType: ChatType.Twitch)));
    await revokePro(tester);

    expect(find.byIcon(JamIcons.padlock), findsOneWidget);
  });

  testWidgets(
      'not-Pro tap on Native still switches the engine (the pane renders '
      'the locked upsell instead)', (tester) async {
    await tester.pumpWidget(wrap(ChatEngineSwitch(
        settingsBox: settingsBox(), chatType: ChatType.Twitch)));
    await revokePro(tester);

    await tester.tap(find.text('Native'));
    await tester.pump();

    expect(settingsBox().get(SettingsKeys.SelectedChatEngine.name),
        ChatEngine.native);

    /// The tap ran its Hive write in the test's FakeAsync zone - close
    /// Hive from inside the zone (same dance as the 'tapping a segment
    /// persists the engine' test above)
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
