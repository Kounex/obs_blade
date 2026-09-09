import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/routing_helper.dart';
import 'package:obs_blade/views/settings/settings.dart';
import 'package:obs_blade/views/settings/widgets/action_block.dart/block_entry.dart';

import '../persistence/support/hive_test_harness.dart';

/// The settings list reads the entitlement straight from the settings box
/// (its HiveBuilder rebuilds on any box change) - no ProStore needed here
void main() {
  late Directory tempDir;
  late HiveTestHarness harness;

  Box<dynamic> settingsBox() => Hive.box(HiveKeys.Settings.name);

  /// The settings landing route carries the tab's ScrollController as its
  /// route arguments (TabBase does this); the Pro route is a sentinel so
  /// the push is assertable
  Widget wrap() => MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
          cupertinoOverrideTheme: const CupertinoThemeData(),
          appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
          buttonTheme: ButtonThemeData(
            colorScheme: ColorScheme.fromSwatch(accentColor: Colors.redAccent),
          ),

          /// Design-system extensions the migrated widgets force-unwrap
          /// (registered by `App._getCurrentTheme` in real runs)
          extensions: const [
            AppStatusColors.standard,
            AppTextColors.standard,
          ],
        ),
        onGenerateRoute: (routeSettings) => MaterialPageRoute(
          builder: (_) => routeSettings.name == SettingsTabRoutingKeys.Pro.route
              ? const Scaffold(body: Text('PAYWALL'))
              : const SettingsView(),
          settings: routeSettings.name == SettingsTabRoutingKeys.Pro.route
              ? routeSettings
              : RouteSettings(name: '/', arguments: ScrollController()),
        ),
      );

  Finder proRow() => find.ancestor(
        of: find.text('OBS Blade Pro'),
        matching: find.byType(BlockEntry),
      );

  /// The Pro row lives in the Support block, well below the fold
  Future<void> scrollToProRow(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('OBS Blade Pro'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('settings_pro_entry');
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

  testWidgets('not-Pro: row shows Inactive and opens the paywall',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await scrollToProRow(tester);
    expect(
      find.descendant(of: proRow(), matching: find.text('Inactive')),
      findsOneWidget,
    );

    await tester.tap(find.text('OBS Blade Pro'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('PAYWALL'), findsOneWidget);
  });

  testWidgets('Pro: row shows Active and opens the paywall (manage state)',
      (tester) async {
    await tester.runAsync(
      () => settingsBox().put(SettingsKeys.BoughtPro.name, true),
    );

    await tester.pumpWidget(wrap());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await scrollToProRow(tester);
    expect(
      find.descendant(of: proRow(), matching: find.text('Active')),
      findsOneWidget,
    );

    await tester.tap(find.text('OBS Blade Pro'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('PAYWALL'), findsOneWidget);
  });
}
