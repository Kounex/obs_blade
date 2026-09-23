import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/utils/modal_handler.dart';

void main() {
  testWidgets('barrier tap dismisses when Material wraps only the sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => ModalHandler.showBaseBottomSheet(
                context: context,
                barrierDismissible: true,
                enableDrag: true,
                maxHeightFraction: 0.72,
                builder: (_) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('sheet body'),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('sheet body'), findsOneWidget);

    await tester.tapAt(const Offset(400, 50));
    await tester.pumpAndSettle();
    expect(find.text('sheet body'), findsNothing);
  });

  Widget scrollingSheet(BuildContext context) => TextButton(
    onPressed: () => ModalHandler.showBaseBottomSheet(
      context: context,
      barrierDismissible: true,
      enableDrag: true,
      maxHeightFraction: 0.86,
      builder: (_) => ListView(
        primary: false,
        children: [
          for (var i = 0; i < 30; i++)
            const SizedBox(height: 48, child: Text('sheet row')),
        ],
      ),
    ),
    child: const Text('open'),
  );

  testWidgets('overscroll on any scrolling sheet dismisses it', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Builder(builder: scrollingSheet)),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('sheet row'), findsWidgets);

    await tester.fling(
      find.text('sheet row').first,
      const Offset(0, 400),
      2000,
    );
    await tester.pumpAndSettle();
    expect(find.text('sheet row'), findsNothing);
  });

  testWidgets('a short overscroll springs any scrolling sheet back', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Builder(builder: scrollingSheet)),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final before = tester.getTopLeft(find.text('sheet row').first);
    final gesture = await tester.startGesture(before + const Offset(40, 12));
    await gesture.moveBy(const Offset(0, 24));
    await gesture.moveBy(const Offset(0, 80));
    await tester.pump();
    expect(
      tester.getTopLeft(find.text('sheet row').first).dy,
      greaterThan(before.dy + 60),
    );
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('sheet row'), findsWidgets);
    expect(
      (tester.getTopLeft(find.text('sheet row').first).dy - before.dy).abs(),
      lessThan(2),
    );
  });

  testWidgets(
    'dragging back up mid-gesture grows the sheet back, not just shrinks it',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Builder(builder: scrollingSheet)),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final before = tester.getTopLeft(find.text('sheet row').first);
      final gesture = await tester.startGesture(before + const Offset(40, 12));

      /// Pull the sheet down (shrinking it) in a few steps.
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 40));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 40));
      await tester.pump();
      final shrunk = tester.getTopLeft(find.text('sheet row').first).dy;
      expect(
        shrunk,
        greaterThan(before.dy + 60),
        reason: 'sanity check: the pull-down actually shrank the sheet',
      );

      /// Reverse direction without releasing - the sheet should follow the
      /// finger back up (grow again), not stay pinned at the shrunk size.
      await gesture.moveBy(const Offset(0, -80));
      await tester.pump();
      final grownBack = tester.getTopLeft(find.text('sheet row').first).dy;
      expect(
        grownBack,
        lessThan(shrunk - 40),
        reason: 'reversing the drag mid-gesture must grow the sheet back up',
      );

      await gesture.up();
      await tester.pumpAndSettle();
    },
  );
}
