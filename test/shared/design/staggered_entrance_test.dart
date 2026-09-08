import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/shared/design/app_motion.dart';
import 'package:obs_blade/shared/design/staggered_entrance.dart';

void main() {
  Widget wrap(Widget child, {bool reduceMotion = false}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: Scaffold(body: child),
        ),
      );

  double opacityOf(WidgetTester tester) => tester
      .widget<Opacity>(find.descendant(
        of: find.byType(StaggeredEntrance),
        matching: find.byType(Opacity),
      ))
      .opacity;

  testWidgets('default entrance stays rise-only and completes', (tester) async {
    await tester.pumpWidget(wrap(const StaggeredEntrance(child: Text('hi'))));
    await tester.pump();

    expect(opacityOf(tester), lessThan(1.0));
    // Rise-only: no scale transform
    expect(
      find.descendant(
        of: find.byType(StaggeredEntrance),
        matching: find.byWidgetPredicate(
            (w) => w is Transform && w.transform.storage[0] != 1.0),
      ),
      findsNothing,
    );

    await tester.pumpAndSettle();
    expect(opacityOf(tester), 1.0);
  });

  testWidgets('scaleFrom adds a scale settle from the given value',
      (tester) async {
    await tester.pumpWidget(wrap(const StaggeredEntrance(
      scaleFrom: 0.985,
      child: Text('hi'),
    )));
    await tester.pump();

    final Transform scale = tester.widget<Transform>(find.descendant(
      of: find.byType(StaggeredEntrance),
      matching: find.byWidgetPredicate(
          (w) => w is Transform && w.transform.storage[0] != 1.0),
    ));
    expect(scale.transform.storage[0], closeTo(0.985, 0.001));

    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<Transform>(find.descendant(
            of: find.byType(StaggeredEntrance),
            matching: find.byType(Transform),
          ))
          .every((t) => (t.transform.storage[0] - 1.0).abs() < 0.001),
      isTrue,
    );
  });

  testWidgets('reduced motion renders at the final value immediately',
      (tester) async {
    await tester.pumpWidget(wrap(
      const StaggeredEntrance(
        index: 5,
        scaleFrom: 0.985,
        child: Text('hi'),
      ),
      reduceMotion: true,
    ));
    await tester.pump();

    expect(opacityOf(tester), 1.0);
    expect(
      find.descendant(
        of: find.byType(StaggeredEntrance),
        matching: find.byWidgetPredicate(
            (w) => w is Transform && w.transform.storage[0] != 1.0),
      ),
      findsNothing,
    );
  });
}
