import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/dashboard_element_card.dart';

import '../persistence/support/hive_test_harness.dart';

/// Card-less dashboard rows (studio mode checkbox, transition controls)
/// right-align with the element cards at every width - on tablets the
/// cards stop at the capped column, and so must the rows.
void main() {
  late Directory tempDir;
  late HiveTestHarness harness;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('card_column_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();
  });

  tearDown(() async {
    await harness.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<(Rect card, Rect row)> pump(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const DashboardElementCard(
                child: SizedBox(
                  key: Key('card'),
                  width: double.infinity,
                  height: 40,
                ),
              ),
              DashboardCardColumn(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(key: const Key('row'), width: 120, height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return (
      tester.getRect(find.byKey(const Key('card'))),
      tester.getRect(find.byKey(const Key('row'))),
    );
  }

  for (final width in [390.0, 1032.0, 1376.0]) {
    testWidgets('right edges line up at $width', (tester) async {
      final (card, row) = await pump(tester, width);

      expect(row.right, closeTo(card.right, 0.01));
      if (width > 800) {
        expect(row.right, lessThan(width - 100), reason: 'not the screen edge');
      }
    });
  }
}
