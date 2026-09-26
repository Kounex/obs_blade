import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/views/intro.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/routing_helper.dart';
import 'package:obs_blade/views/intro/intro.dart';

import '../persistence/support/hive_test_harness.dart';

/// Intro v2: swipe navigation, Skip / Get started persist the v2 seen-key
/// (launch only), the Settings entry writes nothing
void main() {
  late Directory tempDir;

  Box<dynamic> settingsBox() => Hive.box(HiveKeys.Settings.name);

  Widget wrap({bool manually = false}) => MaterialApp(
    theme: ThemeData(
      brightness: Brightness.dark,
      cupertinoOverrideTheme: const CupertinoThemeData(),
      buttonTheme: ButtonThemeData(
        colorScheme: ColorScheme.fromSwatch(accentColor: Colors.redAccent),
      ),
      extensions: const [AppStatusColors.standard, AppTextColors.standard],
    ),
    home: IntroView(manually: manually),
    routes: {
      AppRoutingKeys.Tabs.route: (_) => const Text('tabs'),
      SettingsTabRoutingKeys.Landing.route: (_) => const Text('settings'),
    },
  );

  Future<void> setPhone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(393, 852) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  /// Taps a control whose handler does a Hive `put`: run it on the real
  /// event loop and flush, or the pending write hangs the file at teardown
  /// (handoff gotcha)
  Future<void> tapPersisting(WidgetTester tester, String text) async {
    await tester.runAsync(() async {
      await tester.tap(find.text(text));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await settingsBox().flush();
    });
  }

  /// Mockups loop forever - advance by fixed frames, never pumpAndSettle
  Future<void> advance(WidgetTester tester) async {
    for (int i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('intro_view_test');
    await HiveTestHarness(tempDir).init();
    await Hive.openBox(HiveKeys.Settings.name);
    GetIt.instance.registerLazySingleton<IntroStore>(() => IntroStore());
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('swipes through all four screens, Next ends in Get started', (
    tester,
  ) async {
    await setPhone(tester);
    await tester.pumpWidget(wrap());
    await advance(tester);

    expect(find.text('Your OBS,\nin your pocket.'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await advance(tester);
    expect(GetIt.instance<IntroStore>().currentPage, 1);
    expect(find.text('Your control room.'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await advance(tester);
    expect(find.text('Make it yours.'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await advance(tester);
    expect(find.text('Know how it went.'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await advance(tester);
    expect(GetIt.instance<IntroStore>().currentPage, 2);
  });

  testWidgets('Skip on launch persists the v2 seen-key and opens the tabs', (
    tester,
  ) async {
    await setPhone(tester);
    await tester.pumpWidget(wrap());
    await advance(tester);

    await tapPersisting(tester, 'Skip');
    await advance(tester);

    expect(find.text('tabs'), findsOneWidget);
    expect(settingsBox().get(SettingsKeys.HasUserSeenIntro202609.name), true);
  });

  testWidgets('Get started on the last screen persists and opens the tabs', (
    tester,
  ) async {
    await setPhone(tester);
    await tester.pumpWidget(wrap());
    await advance(tester);

    for (int i = 0; i < 3; i++) {
      await tester.tap(find.text('Next'));
      await advance(tester);
    }
    await tapPersisting(tester, 'Get started');
    await advance(tester);

    expect(find.text('tabs'), findsOneWidget);
    expect(settingsBox().get(SettingsKeys.HasUserSeenIntro202609.name), true);
  });

  testWidgets('Settings entry: Close returns to Settings, writes nothing', (
    tester,
  ) async {
    await setPhone(tester);
    await tester.pumpWidget(wrap(manually: true));
    await advance(tester);

    expect(find.text('Skip'), findsNothing);
    await tester.tap(find.text('Close'));
    await advance(tester);

    expect(find.text('settings'), findsOneWidget);
    expect(settingsBox().get(SettingsKeys.HasUserSeenIntro202609.name), null);
  });

  testWidgets('reduced motion renders every screen statically', (tester) async {
    await setPhone(tester);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(wrap());
    await advance(tester);
    for (int i = 0; i < 3; i++) {
      await tester.tap(find.text('Next'));
      await advance(tester);
    }
    expect(find.text('Know how it went.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
