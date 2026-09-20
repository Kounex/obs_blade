import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/classes/api/stream_stats.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/stream_health_strip.dart';

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
    home: const Scaffold(body: Center(child: StreamHealthStrip())),
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('stream_health_strip');
    harness = HiveTestHarness(tempDir);
    await harness.init();

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

  testWidgets('shows placeholder dashes while no stream is live', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text('KBIT/S'), findsOneWidget);
    expect(find.text('DROPPED'), findsOneWidget);
    expect(find.text('CPU'), findsOneWidget);
    expect(find.text('–'), findsNWidgets(3));
  });

  testWidgets('renders bitrate, dropped frames and cpu once stats flow', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    dashboardStore.latestStreamStats = StreamStats(
      kbitsPerSec: 6120,
      totalTime: 60,
      fps: 60.0,
      renderTotalFrames: 3600,
      renderSkippedFrames: 0,
      outputTotalFrames: 3600,
      outputSkippedFrames: 12,
      averageFrameTime: 1.1,
      cpuUsage: 3.42,
      memoryUsage: 1000.0,
      freeDiskSpace: 9999.0,
    );
    await tester.pump();

    expect(find.text('6120'), findsOneWidget);
    expect(find.text('12 (0.33%)'), findsOneWidget);
    expect(find.text('3.4%'), findsOneWidget);
  });
}
