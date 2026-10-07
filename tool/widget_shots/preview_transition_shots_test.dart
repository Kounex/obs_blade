import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/utils/preview_transition/preview_transition_spec.dart';
import 'package:obs_blade/views/settings/settings.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_preview/preview_transition_painter.dart';

import 'support/shots_harness.dart';

/// The scene preview transitions mid-way (25 / 50 / 75 %) - one row per
/// OBS transition the preview reproduces. Scene A is blue, scene B orange,
/// each with its letter, so direction and order read at a glance.
void main() {
  final harness = ShotsHarness();

  setUpAll(ShotsHarness.loadFonts);
  setUp(harness.setUp);
  tearDown(harness.tearDown);

  Future<ui.Image> scene(
    String letter,
    Color color, {
    Size size = const Size(320, 180),
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(Offset.zero & size, Paint()..color = color);
    canvas.drawCircle(
      const Offset(40, 40),
      18,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );
    final text = TextPainter(
      text: TextSpan(
        text: letter,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 96,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(
      canvas,
      Offset((size.width - text.width) / 2, (size.height - text.height) / 2),
    );
    return recorder.endRecording().toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
  }

  const Duration d = Duration(milliseconds: 300);
  final Map<String, PreviewTransitionSpec> specs = {
    'fade': const PreviewTransitionSpec(
      kind: PreviewTransitionKind.fade,
      duration: d,
    ),
    'fade to color (red, 50%)': const PreviewTransitionSpec(
      kind: PreviewTransitionKind.fadeToColor,
      duration: d,
      color: 0xFFE53935,
    ),
    'swipe left (out)': const PreviewTransitionSpec(
      kind: PreviewTransitionKind.swipe,
      duration: d,
    ),
    'swipe up (in)': const PreviewTransitionSpec(
      kind: PreviewTransitionKind.swipe,
      duration: d,
      direction: PreviewTransitionDirection.up,
      swipeIn: true,
    ),
    'slide right': const PreviewTransitionSpec(
      kind: PreviewTransitionKind.slide,
      duration: d,
      direction: PreviewTransitionDirection.right,
    ),
    'luma linear-h': const PreviewTransitionSpec(
      kind: PreviewTransitionKind.lumaWipe,
      duration: d,
    ),
    'luma clock (soft 0.2)': const PreviewTransitionSpec(
      kind: PreviewTransitionKind.lumaWipe,
      duration: d,
      lumaImage: 'clock.png',
      lumaSoftness: 0.2,
    ),
    'luma iris inverted': const PreviewTransitionSpec(
      kind: PreviewTransitionKind.lumaWipe,
      duration: d,
      lumaImage: 'iris.png',
      lumaInvert: true,
    ),
    'stinger (hold until point)': const PreviewTransitionSpec(
      kind: PreviewTransitionKind.cutAtEnd,
      duration: d,
    ),
  };

  testWidgets('preview transitions mid-way', (tester) async {
    late ui.Image a;
    late ui.Image b;
    late ui.Image a43;
    late ui.Image b43;
    ui.FragmentProgram? program;
    final Map<String, ui.Image?> masks = {};
    await tester.runAsync(() async {
      a = await scene('A', const Color(0xFF1E5AA8));
      b = await scene('B', const Color(0xFFE08A1E));
      a43 = await scene(
        'A',
        const Color(0xFF1E5AA8),
        size: const Size(240, 180),
      );
      b43 = await scene(
        'B',
        const Color(0xFFE08A1E),
        size: const Size(240, 180),
      );
      program = await LumaWipeResources.program();
      for (final spec in specs.values) {
        if (spec.kind == PreviewTransitionKind.lumaWipe) {
          masks[spec.lumaImage] = await LumaWipeResources.mask(spec.lumaImage);
        }
      }
    });
    expect(program, isNotNull, reason: 'luma shader loads');
    expect(masks.values, everyElement(isNotNull), reason: 'masks load');

    Widget cell(
      PreviewTransitionSpec spec,
      double t, {
      bool fourThree = false,
    }) => Padding(
      padding: const EdgeInsets.all(3),
      child: SizedBox(
        width: 112,
        height: 63,
        child: ColoredBox(
          color: Colors.black,
          child: CustomPaint(
            painter: PreviewTransitionPainter(
              from: fourThree ? a43 : a,
              to: fourThree ? b43 : b,
              spec: spec,
              progress: AlwaysStoppedAnimation(t),
              lumaProgram: program,
              lumaMask: masks[spec.lumaImage],
            ),
          ),
        ),
      ),
    );

    await harness.shot(
      tester,
      'preview_transitions',
      SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final entry in specs.entries) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                child: Text(entry.key),
              ),
              Row(
                children: [
                  for (final t in [0.25, 0.5, 0.75]) cell(entry.value, t),
                ],
              ),
            ],
            const Padding(
              padding: EdgeInsets.fromLTRB(6, 6, 6, 0),
              child: Text('4:3 canvas: swipe left / luma clock / slide right'),
            ),
            Row(
              children: [
                cell(specs['swipe left (out)']!, 0.5, fourThree: true),
                cell(specs['luma clock (soft 0.2)']!, 0.5, fourThree: true),
                cell(specs['slide right']!, 0.5, fourThree: true),
              ],
            ),
          ],
        ),
      ),
      size: const Size(390, 1000),
    );
  });

  /// The Settings → Dashboard toggle (scrolled to it), phone + narrow
  for (final entry in {
    'preview_transitions_setting': kShotPhone,
    'preview_transitions_setting_narrow': const Size(320, 640),
  }.entries) {
    testWidgets(entry.key, (tester) async {
      tester.view.physicalSize = entry.value * 2.0;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      await harness.shot(
        tester,
        entry.key,
        Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final finder = find.text('Preview Transitions');
              if (finder.evaluate().isNotEmpty) {
                Scrollable.ensureVisible(
                  finder.evaluate().first,
                  alignment: 0.5,
                );
              }
            });
            return const SettingsView();
          },
        ),
        size: entry.value,
      );
    });
  }
}
