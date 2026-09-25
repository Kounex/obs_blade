import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/classes/api/input.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_content/audio_inputs/audio_settings_sheet.dart';

import '../persistence/support/hive_test_harness.dart';

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
    home: const Scaffold(body: AudioSettingsSheet(inputName: 'Mic')),
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('audio_settings_sheet');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);

    /// No active session: requestInputAudioSettings bails quietly
    GetIt.instance.registerSingleton<NetworkStore>(NetworkStore());
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

  testWidgets('shows loaded balance + monitoring and follows store changes', (
    tester,
  ) async {
    dashboardStore.allInputs = ObservableList.of([
      const Input(
        inputKind: 'wasapi_input_capture',
        inputName: 'Mic',
        unversionedInputKind: 'wasapi_input_capture',
        audioBalance: 0.25,
        monitorType: 'OBS_MONITORING_TYPE_MONITOR_ONLY',
      ),
    ]);

    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text('L 50%'), findsOneWidget);
    expect(
      tester
          .widget<CupertinoSlidingSegmentedControl<String>>(
            find.byType(CupertinoSlidingSegmentedControl<String>),
          )
          .groupValue,
      'OBS_MONITORING_TYPE_MONITOR_ONLY',
    );

    dashboardStore.allInputs = ObservableList.of([
      dashboardStore.allInputs.single.copyWith(audioBalance: 0.5),
    ]);
    await tester.pump();
    expect(find.text('Center'), findsOneWidget);
  });
}
