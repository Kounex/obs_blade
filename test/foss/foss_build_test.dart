import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/enums/chat_engine.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/pro_store.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/build_flavor.dart';
import 'package:obs_blade/utils/pro_purchase_service.dart';
import 'package:obs_blade/views/chat/chat_view.dart';
import 'package:obs_blade/views/settings/faq/faq.dart';
import 'package:obs_blade/views/settings/settings.dart';

import '../persistence/support/hive_test_harness.dart';
import '../pro/support/fake_pro_purchase_gateway.dart';

/// The FOSS build's UI (docs/foss-build.md): Pro left out entirely, not
/// locked. Runs only with the FOSS define on the regular tree:
///
///   flutter test --dart-define=OBS_BLADE_FOSS=true test/foss/
///
/// Every case starts from a state that WOULD show Pro in the store build
/// (bought flag, debug override, persisted native engine) - the FOSS
/// build must ignore all of it.
void main() {
  /// FOSS build only - run with --dart-define=OBS_BLADE_FOSS=true
  const bool skip = !kFoss;

  late Directory tempDir;
  late HiveTestHarness harness;
  late ProStore proStore;

  Box<dynamic> settingsBox() => Hive.box(HiveKeys.Settings.name);

  Widget wrap(Widget child, {Object? arguments}) => MaterialApp(
    theme: ThemeData(
      cupertinoOverrideTheme: const CupertinoThemeData(),

      /// The app theme always sets this (lib/app.dart) and the
      /// translucent nav bar wrapper non-Apple branch force-unwraps it
      appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
      extensions: const [AppStatusColors.standard, AppTextColors.standard],
    ),
    onGenerateRoute: (routeSettings) => MaterialPageRoute(
      builder: (_) => child,
      settings: RouteSettings(name: '/', arguments: arguments),
    ),
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('foss_build');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    await settingsBox().put(SettingsKeys.BoughtPro.name, true);
    await settingsBox().put(SettingsKeys.ProDebugOverride.name, true);
    await settingsBox().put(SettingsKeys.ProColdStartRestoreDone.name, true);
    await settingsBox().put(
      SettingsKeys.SelectedChatEngine.name,
      ChatEngine.native,
    );

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

  test('no Pro entitlement, whatever the box says', () {
    expect(proStore.boughtPro, isTrue);
    expect(proStore.debugOverride, isTrue);
    expect(proStore.isPro, isFalse);
  }, skip: skip);

  test('no native engine and no native-only chat type', () {
    for (final ChatType type in ChatType.values) {
      expect(nativeChatAvailableFor(type), isFalse, reason: type.name);
    }
    expect(selectableChatTypes, isNot(contains(ChatType.Combined)));
    expect(selectableChatTypes, [
      ChatType.Twitch,
      ChatType.YouTube,
      ChatType.Owncast,
      ChatType.Kick,
    ]);
  }, skip: skip);

  testWidgets('chat tab: WebView chat only - no segments, engine switch '
      'or upsell', (tester) async {
    await tester.pumpWidget(wrap(const ChatView()));
    await tester.pump();

    expect(find.text('Twitch Chat'), findsOneWidget);
    expect(find.byKey(const Key('chat-tab-segments')), findsNothing);
    expect(find.text('Activity'), findsNothing);
    expect(find.text('Native'), findsNothing);
    expect(find.text('Explore Pro'), findsNothing);
    expect(find.textContaining('OBS Blade Pro'), findsNothing);

    /// The type picker offers the WebView platforms, no Combined
    await tester.tap(find.byType(DropdownButton<ChatType>));
    await tester.pumpAndSettle();
    expect(find.text('Kick'), findsWidgets);
    expect(find.text('Combined'), findsNothing);
    expect(tester.takeException(), isNull);
  }, skip: skip);

  testWidgets('settings: no Pro or Custom Theme rows, Tip Jar stays', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const SettingsView(), arguments: ScrollController()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await tester.scrollUntilVisible(
      find.text('Tip Jar'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.text('Tip Jar'), findsOneWidget);
    expect(find.text('OBS Blade Pro'), findsNothing);
    expect(find.text('Custom Theme'), findsNothing);
    expect(find.text('True Dark Mode'), findsOneWidget);
  }, skip: skip);

  testWidgets('FAQ: no Pro answers', (tester) async {
    await tester.pumpWidget(wrap(const FAQView()));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Which chats can I use?'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.textContaining('OBS Blade Pro'), findsNothing);
    expect(find.textContaining('(Pro)'), findsNothing);
    expect(find.textContaining('Two ways to show it'), findsNothing);
    expect(
      find.textContaining('The Twitch, YouTube, Kick or Owncast chat page'),
      findsOneWidget,
    );
  }, skip: skip);
}
