import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/settings/settings.dart';
import 'package:obs_blade/views/settings/widgets/action_block.dart/block_entry.dart';

import '../persistence/support/hive_test_harness.dart';

/// Settings -> Theme -> Bars & Sheets: Glass / Clear / Solid for every
/// floating surface (issue #106)
void main() {
  late Directory tempDir;
  late HiveTestHarness harness;

  Box<dynamic> settingsBox() => Hive.box(HiveKeys.Settings.name);

  /// The settings landing route carries the tab's ScrollController as its
  /// route arguments (TabBase does this)
  Widget wrap() => MaterialApp(
    theme: ThemeData(
      brightness: Brightness.dark,
      cupertinoOverrideTheme: const CupertinoThemeData(),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
      buttonTheme: ButtonThemeData(
        colorScheme: ColorScheme.fromSwatch(accentColor: Colors.redAccent),
      ),
      extensions: const [AppStatusColors.standard, AppTextColors.standard],
    ),
    onGenerateRoute: (routeSettings) => MaterialPageRoute(
      builder: (_) => const SettingsView(),
      settings: RouteSettings(name: '/', arguments: ScrollController()),
    ),
  );

  Finder styleRow() => find.ancestor(
    of: find.text('Bars & Sheets'),
    matching: find.byType(BlockEntry),
  );

  CupertinoSlidingSegmentedControl<SurfaceStyle> control(WidgetTester tester) =>
      tester.widget(
        find.descendant(
          of: styleRow(),
          matching: find.byType(CupertinoSlidingSegmentedControl<SurfaceStyle>),
        ),
      );

  Future<void> scrollToStyleRow(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Bars & Sheets'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('surface_style_entry');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);

    /// The Support block reads PackageInfo.fromPlatform() - no plugin in
    /// tests
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/package_info'),
          (call) async => <String, dynamic>{
            'appName': 'obs_blade',
            'packageName': 'de.obsblade.test',
            'version': '1.0.0',
            'buildNumber': '1',
            'buildSignature': 'test',
          },
        );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/package_info'),
          null,
        );
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('defaults to Glass, picking Solid persists to the settings box', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await scrollToStyleRow(tester);
    expect(control(tester).groupValue, SurfaceStyle.glass);
    expect(
      find.descendant(of: styleRow(), matching: find.text('Clear')),
      findsOneWidget,
    );

    /// The control writes to the settings Hive box (real I/O) - run the tap
    /// in a real zone and poll until the write landed
    await tester.runAsync(() async {
      await tester.tap(
        find.descendant(of: styleRow(), matching: find.text('Solid')),
      );
      await tester.pump();
      for (var i = 0; i < 250; i++) {
        if (settingsBox().get(SettingsKeys.SurfaceStyle.name) == 'solid') {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });

    expect(settingsBox().get(SettingsKeys.SurfaceStyle.name), 'solid');
    await tester.pump();
    expect(control(tester).groupValue, SurfaceStyle.solid);
  });
}
