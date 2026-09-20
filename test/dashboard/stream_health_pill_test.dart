import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/classes/api/stream_stats.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/stream_health_pill.dart';

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
    home: const Scaffold(body: Center(child: StreamHealthPill())),
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('stream_health_pill');
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

  testWidgets('shows a placeholder while no stream is live', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text('Not streaming'), findsOneWidget);
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

    expect(find.text('6120 kbit/s'), findsOneWidget);
    expect(find.text('Dropped 12 (0.33%)'), findsOneWidget);
    expect(find.text('CPU 3.4%'), findsOneWidget);
  });
}
