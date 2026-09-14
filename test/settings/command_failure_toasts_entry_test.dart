import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/base/adaptive_switch.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/settings/settings.dart';
import 'package:obs_blade/views/settings/widgets/action_block.dart/block_entry.dart';

import '../persistence/support/hive_test_harness.dart';

/// Kill-switch for the command-ack failure toasts (Settings -> General)
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

  Finder alertRow() => find.ancestor(
    of: find.text('Command Failure Alerts'),
    matching: find.byType(BlockEntry),
  );

  Future<void> scrollToAlertRow(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Command Failure Alerts'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'command_failure_toasts_entry',
    );
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

  testWidgets('row defaults to on and toggling persists to the settings box', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await scrollToAlertRow(tester);

    final switchWidget = tester.widget<BaseAdaptiveSwitch>(
      find.descendant(
        of: alertRow(),
        matching: find.byType(BaseAdaptiveSwitch),
      ),
    );
    expect(switchWidget.value, isTrue);

    /// The switch writes to the settings Hive box (real I/O) - run the tap
    /// in a real zone so the write completes instead of hanging the suite
    await tester.runAsync(() async {
      await tester.tap(
        find.descendant(of: alertRow(), matching: find.byType(Switch)),
      );
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });

    expect(settingsBox().get(SettingsKeys.CommandFailureToasts.name), isFalse);

    await tester.pump();
    expect(
      tester
          .widget<BaseAdaptiveSwitch>(
            find.descendant(
              of: alertRow(),
              matching: find.byType(BaseAdaptiveSwitch),
            ),
          )
          .value,
      isFalse,
    );
  });
}
