import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/views/statistics/statistic_detail/statistic_detail.dart';
import 'package:obs_blade/views/statistics/statistic_detail/widgets/stats_chart.dart';

import '../persistence/support/hive_test_harness.dart';

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;

  /// BaseCard reads the theme settings from the settings box
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('stats_chart_grid_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();
  });

  tearDown(() async {
    await harness.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  final List<int> times = List.generate(30, (i) => i * 60000);

  List<StatsChart> charts() => [
    for (final name in ['FPS', 'CPU Usage', 'kbit/s', 'Memory Usage'])
      StatsChart(
        data: List.generate(30, (i) => 50.0 + i % 5),
        dataTimesMS: times,
        dataName: name,
        streamEndedMS: times.last,
        totalTime: 1800,
      ),
  ];

  Future<List<Rect>> pumpGrid(
    WidgetTester tester, {
    required double width,
    required int columns,
  }) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(
          extensions: [AppTextColors.standard, AppStatusColors.standard],
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Center(
              child: SizedBox(
                width: width,
                child: StatsChartGrid(charts: charts(), columns: columns),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tester
        .widgetList<StatsChart>(find.byType(StatsChart))
        .map((c) => tester.getRect(find.byWidget(c)))
        .toList();
  }

  testWidgets('tablet: two charts per row, together filling the width', (
    tester,
  ) async {
    // the detail's wide column minus its horizontal padding
    const double width = 1040 - 2 * AppSpacing.lg;
    final rects = await pumpGrid(tester, width: width, columns: 2);

    expect(rects[0].top, rects[1].top, reason: 'first row: FPS + CPU');
    expect(rects[2].top, rects[3].top, reason: 'second row');
    expect(rects[2].top, greaterThan(rects[0].bottom));
    expect(rects[1].left, greaterThan(rects[0].right));
  });

  testWidgets('tablet columns fall back to one row each when a chart would '
      'get too narrow', (tester) async {
    final rects = await pumpGrid(tester, width: 560, columns: 2);

    expect(rects[1].top, greaterThan(rects[0].bottom));
  });

  testWidgets('phone: one chart per row at full width', (tester) async {
    final rects = await pumpGrid(tester, width: 390, columns: 1);

    expect(rects[1].top, greaterThan(rects[0].bottom));
  });
}
