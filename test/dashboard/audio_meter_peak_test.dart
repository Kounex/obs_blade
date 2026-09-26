import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/classes/api/input.dart';
import 'package:obs_blade/types/classes/api/input_channel.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_content/audio_inputs/audio_slider.dart';

import '../persistence/support/hive_test_harness.dart';

Input _mic(double mul) => Input(
  inputKind: 'coreaudio_input_capture',
  inputName: 'Mic',
  unversionedInputKind: 'coreaudio_input_capture',
  inputLevelsMul: [InputChannel(current: mul, average: mul, potential: mul)],
);

/// The peak-hold tick sits at the left edge of a 2px container inside the
/// meter's Stack - read its `left` via the AnimatedPositioned
double? peakLeft(WidgetTester tester) {
  final finder = find.byType(AnimatedPositioned);
  if (finder.evaluate().isEmpty) return null;
  return tester.widget<AnimatedPositioned>(finder.first).left;
}

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('audio_meter_peak');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    GetIt.instance.registerSingleton<NetworkStore>(NetworkStore());
    GetIt.instance.registerSingleton<DashboardStore>(DashboardStore());
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Widget wrap(Input input) => MaterialApp(
    theme: ThemeData(
      brightness: Brightness.dark,
      cupertinoOverrideTheme: const CupertinoThemeData(),
      extensions: const [AppStatusColors.standard, AppTextColors.standard],
    ),
    home: Scaffold(
      body: SizedBox(width: 400, child: AudioSlider(input: input)),
    ),
  );

  testWidgets('a rise that stays below the settled tick still lets it fall', (
    tester,
  ) async {
    /// Loud → the tick pins high
    await tester.pumpWidget(wrap(_mic(1.0)));
    final double high = peakLeft(tester)!;

    /// Quiet → hold, then decay all the way down to the quiet level
    await tester.pumpWidget(wrap(_mic(0.01)));
    await tester.pump(const Duration(seconds: 2));
    final double settledLow = peakLeft(tester)!;
    expect(settledLow, lessThan(high));

    /// Medium rise (below where the tick was, above where it settled):
    /// tick follows up, then must fall again once the level drops
    await tester.pumpWidget(wrap(_mic(0.2)));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(wrap(_mic(0.01)));
    await tester.pump(const Duration(seconds: 2));
    expect(peakLeft(tester), closeTo(settledLow, 0.5));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('meters that stop (silence / mute) drop the tick to zero', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(_mic(1.0)));
    expect(peakLeft(tester), isNotNull);

    /// OBS stops sending levels for the input: the last event had levels,
    /// the next rebuild has none (empty channel list)
    await tester.pumpWidget(
      wrap(
        const Input(
          inputKind: 'coreaudio_input_capture',
          inputName: 'Mic',
          unversionedInputKind: 'coreaudio_input_capture',
          inputLevelsMul: [],
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    expect(peakLeft(tester), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a lower rise while the tick is settled above starts the fall', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(_mic(1.0)));
    final double high = peakLeft(tester)!;

    /// Lower level arrives before the hold ends - the tick holds, then must
    /// fall to it even if no further meter update arrives
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(wrap(_mic(0.1)));
    await tester.pump(const Duration(seconds: 3));
    expect(peakLeft(tester), lessThan(high));

    await tester.pumpWidget(const SizedBox());
  });
}
