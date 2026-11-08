import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/shared/general/base/sheet.dart';
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
                height: BaseSheetHeight.standard,
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
      height: BaseSheetHeight.tall,
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

  testWidgets('an ordinary-speed fling starting inside the scrollable content '
      'dismisses too (not just an extreme one)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Builder(builder: scrollingSheet)),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('sheet row'), findsWidgets);

    /// Just above the fling-velocity threshold (matches Flutter's own
    /// BottomSheet _kMinFlingVelocity) - not the extreme 2000 above,
    /// which would pass even against a much higher/wrong threshold and
    /// wouldn't actually prove the threshold is reachable.
    await tester.fling(find.text('sheet row').first, const Offset(0, 300), 800);
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

  testWidgets('reversal follows the finger gradually (no snap-to-full) and the '
      'drag stays live for further moves afterward', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Builder(builder: scrollingSheet)),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final before = tester.getTopLeft(find.text('sheet row').first);
    final gesture = await tester.startGesture(before + const Offset(40, 12));

    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    final shrunk = tester.getTopLeft(find.text('sheet row').first).dy;

    /// Reverse in small steps - each one should move the sheet a little,
    /// not snap it all the way back on the very first step (a
    /// `ScrollPosition.jumpTo` mid-drag was found to do exactly that, by
    /// replacing the position's own active drag activity).
    await gesture.moveBy(const Offset(0, -10));
    await tester.pump();
    final afterStep1 = tester.getTopLeft(find.text('sheet row').first).dy;
    expect(
      afterStep1,
      lessThan(shrunk),
      reason: 'the first reversal step should grow the sheet a little',
    );
    expect(
      afterStep1,
      greaterThan(before.dy + 20),
      reason: 'a single small reversal step must not snap all the way back',
    );

    /// The same touch, still down, must still be driving the sheet - not
    /// dead until a lift-and-restart.
    await gesture.moveBy(const Offset(0, -10));
    await tester.pump();
    final afterStep2 = tester.getTopLeft(find.text('sheet row').first).dy;
    expect(
      afterStep2,
      lessThan(afterStep1),
      reason:
          'a second reversal step in the same unlifted gesture must '
          'keep growing the sheet',
    );

    await gesture.up();
    await tester.pumpAndSettle();
  });

  /// Content that fits without scrolling at all (maxScrollExtent == 0, e.g.
  /// a short setup form) - both pull directions are "out of range", so a
  /// reversal reports as another OverscrollNotification (positive this
  /// time) instead of a ScrollUpdateNotification.
  Widget shortSheet(BuildContext context) => TextButton(
    onPressed: () => ModalHandler.showBaseBottomSheet(
      context: context,
      height: BaseSheetHeight.tall,
      builder: (_) => ListView(
        primary: false,
        children: const [SizedBox(height: 48, child: Text('short row'))],
      ),
    ),
    child: const Text('open short'),
  );

  testWidgets(
    'dragging back up mid-gesture grows a non-scrolling (short-content) '
    'sheet back too',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Builder(builder: shortSheet)),
        ),
      );
      await tester.tap(find.text('open short'));
      await tester.pumpAndSettle();

      final before = tester.getTopLeft(find.text('short row'));
      final gesture = await tester.startGesture(before + const Offset(40, 12));

      await gesture.moveBy(const Offset(0, 20));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 40));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 40));
      await tester.pump();
      final shrunk = tester.getTopLeft(find.text('short row')).dy;
      expect(
        shrunk,
        greaterThan(before.dy + 60),
        reason: 'sanity check: the pull-down actually shrank the sheet',
      );

      await gesture.moveBy(const Offset(0, -80));
      await tester.pump();
      final grownBack = tester.getTopLeft(find.text('short row')).dy;
      expect(
        grownBack,
        lessThan(shrunk - 40),
        reason: 'reversing the drag mid-gesture must grow the sheet back up',
      );

      await gesture.up();
      await tester.pumpAndSettle();
    },
  );

  Widget opener({
    TargetPlatform platform = TargetPlatform.android,
    BaseSheetHeight height = BaseSheetHeight.standard,
    required Widget Function(BuildContext) builder,
  }) => MaterialApp(
    theme: ThemeData(platform: platform),
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => ModalHandler.showBaseBottomSheet(
            context: context,
            height: height,
            builder: builder,
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );

  /// Tablets: every sheet is a centered card, never the full width
  /// (the dashboard / settings sheets were full width before 2026-11)
  testWidgets('a sheet is at most kBaseSheetMaxWidth wide, centered', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1180, 820);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      opener(
        builder: (_) => const SizedBox(
          key: Key('wide-content'),
          width: double.infinity,
          height: 120,
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final Rect sheet = tester.getRect(find.byKey(const Key('wide-content')));
    expect(sheet.width, kBaseSheetMaxWidth);
    expect(sheet.center.dx, 1180 / 2);
  });

  testWidgets("a sheet is at most its height's share of the screen", (
    tester,
  ) async {
    for (final height in BaseSheetHeight.values) {
      await tester.pumpWidget(
        opener(
          height: height,
          builder: (_) => ListView(
            primary: false,
            children: [
              for (var i = 0; i < 60; i++)
                const SizedBox(height: 48, child: Text('row')),
            ],
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final double screen =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final Rect list = tester.getRect(find.byType(ListView));
      expect(
        list.height,
        lessThanOrEqualTo(screen * height.fraction),
        reason: height.name,
      );
      expect(
        list.height,
        greaterThan(screen * height.fraction - 60),
        reason: '${height.name}: a long list fills its cap',
      );
      Navigator.of(tester.element(find.byType(ListView))).pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('frosted glass on iOS, solid card on Android', (tester) async {
    for (final (platform, glass) in [
      (TargetPlatform.iOS, true),
      (TargetPlatform.android, false),
    ]) {
      await tester.pumpWidget(
        opener(
          platform: platform,
          builder: (_) => const SizedBox(key: Key('content'), height: 120),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(
        find.byType(BackdropFilter),
        glass ? findsOneWidget : findsNothing,
        reason: platform.name,
      );
      Navigator.of(tester.element(find.byKey(const Key('content')))).pop();
      await tester.pumpAndSettle();
    }
  });

  /// The date picker sheet: running a wheel past its first entry picks a
  /// date, it doesn't drag the sheet away
  testWidgets('a picker wheel at its start does not drag the sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      opener(
        builder: (_) => BaseSheetScaffold(
          header: const BaseSheetTitle('Date'),
          body: SizedBox(
            height: 216,
            child: CupertinoPicker(
              itemExtent: 32,
              onSelectedItemChanged: (_) {},
              children: [for (var i = 0; i < 10; i++) Text('item $i')],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.fling(find.text('item 0'), const Offset(0, 300), 1500);
    await tester.pumpAndSettle();
    expect(find.text('Date'), findsOneWidget);
  });

  testWidgets('a BaseSheetScaffold sheet closes by dragging its header', (
    tester,
  ) async {
    await tester.pumpWidget(
      opener(
        builder: (_) => const BaseSheetScaffold(
          header: BaseSheetTitle('Title'),
          body: SizedBox(height: 200),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Title'), findsOneWidget);

    await tester.fling(find.text('Title'), const Offset(0, 400), 1500);
    await tester.pumpAndSettle();
    expect(find.text('Title'), findsNothing);
  });

  /// Review 2026-11-08: with the keyboard up, min(cap, screen - keyboard)
  /// left the sheet the whole space above the keyboard and its header
  /// went up behind the status bar / Dynamic Island
  testWidgets('with the keyboard up a tall sheet stays below the status bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 59, bottom: 34);
    tester.view.viewInsets = const FakeViewPadding(bottom: 336);
    addTearDown(tester.view.reset);

    for (final height in BaseSheetHeight.values) {
      await tester.pumpWidget(
        opener(
          height: height,
          builder: (_) => BaseSheetScaffold(
            header: BaseSheetTitle('Sheet ${height.name}'),
            bodyIsScrollable: true,
            body: ListView(
              primary: false,
              children: [
                for (var i = 0; i < 60; i++)
                  const SizedBox(height: 48, child: Text('row')),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final double top = tester
          .getTopLeft(find.text('Sheet ${height.name}'))
          .dy;
      expect(top, greaterThanOrEqualTo(59), reason: height.name);
      Navigator.of(tester.element(find.text('Sheet ${height.name}'))).pop();
      await tester.pumpAndSettle();
    }
  });
}
