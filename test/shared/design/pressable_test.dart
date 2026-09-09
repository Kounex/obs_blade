import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/shared/design/app_motion.dart';
import 'package:obs_blade/shared/design/pressable.dart';

void main() {
  Widget wrap(Widget child, {bool reduceMotion = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Scaffold(body: Center(child: child)),
    ),
  );

  double pressedScale(WidgetTester tester) {
    final Transform transform = tester.widget<Transform>(
      find.descendant(
        of: find.byType(Pressable),
        matching: find.byType(Transform),
      ),
    );
    return transform.transform.storage[0];
  }

  double pressedOpacity(WidgetTester tester) => tester
      .widget<Opacity>(
        find.descendant(
          of: find.byType(Pressable),
          matching: find.byType(Opacity),
        ),
      )
      .opacity;

  testWidgets('default press scales to 0.97 and flashes opacity', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(Pressable(onTap: () {}, child: const Text('tap'))),
    );

    expect(pressedScale(tester), 1.0);

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.text('tap')),
    );
    await tester.pump();
    await tester.pump(AppMotion.instant);
    expect(pressedScale(tester), closeTo(0.97, 0.001));
    expect(pressedOpacity(tester), closeTo(0.88, 0.001));

    await gesture.up();
    await tester.pump();
    await tester.pump(AppMotion.fast);
    expect(pressedScale(tester), closeTo(1.0, 0.01));
    expect(pressedOpacity(tester), closeTo(1.0, 0.01));
  });

  testWidgets('custom scale parameter is honored', (tester) async {
    await tester.pumpWidget(
      wrap(Pressable(onTap: () {}, scale: 0.9, child: const Text('tap'))),
    );

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.text('tap')),
    );
    await tester.pump();
    await tester.pump(AppMotion.instant);
    expect(pressedScale(tester), closeTo(0.9, 0.001));
    await gesture.up();
    await tester.pump();
  });

  testWidgets('scale outside 0.85-0.97 asserts', (tester) async {
    expect(
      () => Pressable(scale: 0.5, child: const Text('tap')),
      throwsAssertionError,
    );
    expect(
      () => Pressable(scale: 0.99, child: const Text('tap')),
      throwsAssertionError,
    );
  });

  testWidgets('reduced motion drops the scale, keeps the opacity flash', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        Pressable(onTap: () {}, child: const Text('tap')),
        reduceMotion: true,
      ),
    );

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.text('tap')),
    );
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(Pressable),
        matching: find.byType(Transform),
      ),
      findsNothing,
    );
    expect(pressedOpacity(tester), closeTo(0.88, 0.001));

    await gesture.up();
    await tester.pump();
    expect(pressedOpacity(tester), closeTo(1.0, 0.001));
  });
}
