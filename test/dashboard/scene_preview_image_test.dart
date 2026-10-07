import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/utils/preview_transition/preview_transition_spec.dart';
import 'package:obs_blade/utils/preview_transition/preview_transition_tracker.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_preview/preview_transition_painter.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_preview/scene_preview_image.dart';

Future<Uint8List> _png(Color color) async {
  final recorder = ui.PictureRecorder();
  Canvas(
    recorder,
  ).drawRect(const Rect.fromLTWH(0, 0, 32, 18), Paint()..color = color);
  final image = await recorder.endRecording().toImage(32, 18);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

Finder get _painter => find.byWidgetPredicate(
  (widget) =>
      widget is CustomPaint && widget.painter is PreviewTransitionPainter,
);

void main() {
  late Uint8List a;
  late Uint8List b;
  late Uint8List b2;

  StartPreviewTransition transition(int id, {int ms = 300}) =>
      StartPreviewTransition(
        id: id,
        fromBytes: a,
        toBytes: b,
        spec: PreviewTransitionSpec(
          kind: PreviewTransitionKind.fade,
          duration: Duration(milliseconds: ms),
        ),
      );

  Widget host(
    Uint8List bytes,
    StartPreviewTransition? transition, {
    bool disableAnimations = false,
  }) => MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 320,
          height: 180,
          child: ScenePreviewImage(bytes: bytes, transition: transition),
        ),
      ),
    ),
  );

  /// Image decoding runs outside the fake clock
  Future<void> settleDecode(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
  }

  setUpAll(() async {
    a = await _png(Colors.blue);
    b = await _png(Colors.orange);
    b2 = await _png(Colors.green);
  });

  testWidgets('plays a new transition and drops the overlay at its end', (
    tester,
  ) async {
    await tester.pumpWidget(host(a, null));
    await settleDecode(tester);
    expect(_painter, findsNothing);

    await tester.pumpWidget(host(b, transition(1)));
    await settleDecode(tester);
    expect(_painter, findsOneWidget);

    /// The new scene's next frame keeps playing under the transition
    await tester.pumpWidget(host(b2, transition(1)));
    await settleDecode(tester);
    expect(_painter, findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(_painter, findsNothing);
  });

  testWidgets('a transition that was there before mounting never replays', (
    tester,
  ) async {
    await tester.pumpWidget(host(b, transition(7)));
    await settleDecode(tester);
    expect(_painter, findsNothing);
  });

  testWidgets('reduce motion: cut, no overlay', (tester) async {
    await tester.pumpWidget(host(a, null, disableAnimations: true));
    await tester.pumpWidget(host(b, transition(2), disableAnimations: true));
    await settleDecode(tester);
    expect(_painter, findsNothing);
  });

  testWidgets('the store dropping the transition (reset) stops it', (
    tester,
  ) async {
    await tester.pumpWidget(host(a, null));
    await tester.pumpWidget(host(b, transition(3, ms: 5000)));
    await settleDecode(tester);
    expect(_painter, findsOneWidget);

    await tester.pumpWidget(host(b, null));
    await tester.pump();
    expect(_painter, findsNothing);
  });

  testWidgets('a new transition replaces a running one', (tester) async {
    await tester.pumpWidget(host(a, null));
    await tester.pumpWidget(host(b, transition(4, ms: 5000)));
    await settleDecode(tester);
    await tester.pumpWidget(host(b, transition(5, ms: 300)));
    await settleDecode(tester);
    expect(_painter, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(_painter, findsNothing);
  });
}
