import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/reconnect_toast.dart';

import '../persistence/support/hive_test_harness.dart';

/// The lost state is carried by the inline stale badges - the toast only
/// flashes "Reconnected" once the socket is back
void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late DashboardStore dashboardStore;

  Widget wrap() => MaterialApp(
    theme: ThemeData(
      brightness: Brightness.dark,
      cupertinoOverrideTheme: const CupertinoThemeData(),
      extensions: const [AppStatusColors.standard, AppTextColors.standard],
    ),
    home: const Scaffold(body: Center(child: ReconnectToast())),
  );

  double opacity(WidgetTester tester) => tester
      .widget<FadeTransition>(
        find.descendant(
          of: find.byType(ReconnectToast),
          matching: find.byType(FadeTransition),
        ),
      )
      .opacity
      .value;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('reconnect_toast');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);

    dashboardStore = DashboardStore();
    GetIt.instance.registerSingleton<DashboardStore>(dashboardStore);
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('stays hidden while reconnecting, flashes once back', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    dashboardStore.reconnecting = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(opacity(tester), 0.0);

    dashboardStore.reconnecting = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Reconnected to OBS'), findsOneWidget);
    expect(opacity(tester), greaterThan(0.99));

    /// 3s visible, then fades out
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 400));
    expect(opacity(tester), 0.0);
  });
}
