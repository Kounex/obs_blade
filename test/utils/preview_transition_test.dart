import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/utils/preview_transition/preview_transition_spec.dart';
import 'package:obs_blade/utils/preview_transition/preview_transition_tracker.dart';

Uint8List _frame(int marker) => Uint8List.fromList([marker]);

const PreviewTransitionSpec _fade = PreviewTransitionSpec(
  kind: PreviewTransitionKind.fade,
  duration: Duration(milliseconds: 300),
);

void main() {
  group('resolvePreviewTransitionSpec', () {
    test('settings without defaults fall back to OBS defaults', () {
      /// GetCurrentSceneTransition leaves defaults out
      /// (ObsDataToJson(..., includeDefault = false))
      final swipe = resolvePreviewTransitionSpec(
        kind: 'swipe_transition',
        settings: const {},
        duration: const Duration(milliseconds: 200),
      );
      expect(swipe.kind, PreviewTransitionKind.swipe);
      expect(swipe.direction, PreviewTransitionDirection.left);
      expect(swipe.swipeIn, isFalse);
      expect(swipe.duration, const Duration(milliseconds: 200));

      final toColor = resolvePreviewTransitionSpec(
        kind: 'fade_to_color_transition',
      );
      expect(toColor.color, 0xFF000000);
      expect(toColor.switchPoint, 0.5);
      expect(toColor.duration, kDefaultTransitionDuration);

      final luma = resolvePreviewTransitionSpec(kind: 'wipe_transition');
      expect(luma.kind, PreviewTransitionKind.lumaWipe);
      expect(luma.lumaImage, 'linear-h.png');
      expect(luma.lumaSoftness, closeTo(0.03, 1e-9));
      expect(luma.lumaInvert, isFalse);
    });

    test('reads the settings OBS sends', () {
      final slide = resolvePreviewTransitionSpec(
        kind: 'slide_transition',
        settings: {'direction': 'up'},
      );
      expect(slide.direction, PreviewTransitionDirection.up);

      final swipe = resolvePreviewTransitionSpec(
        kind: 'swipe_transition',
        settings: {'direction': 'down', 'swipe_in': true},
      );
      expect(swipe.direction, PreviewTransitionDirection.down);
      expect(swipe.swipeIn, isTrue);

      final luma = resolvePreviewTransitionSpec(
        kind: 'wipe_transition',
        settings: {
          'luma_image': 'clock.png',
          'luma_softness': 0.5,
          'luma_invert': true,
        },
      );
      expect(luma.lumaImage, 'clock.png');
      expect(luma.lumaSoftness, 0.5);
      expect(luma.lumaInvert, isTrue);
    });

    test('fade to color: OBS color is ABGR, switch point in percent', () {
      final spec = resolvePreviewTransitionSpec(
        kind: 'fade_to_color_transition',

        /// red 0x11, green 0x22, blue 0x33 - OBS keeps red in the low byte
        settings: {'color': 0x00332211, 'switch_point': 25},
      );
      expect(spec.color, 0xFF112233);
      expect(spec.switchPoint, 0.25);
    });

    test('cut has nothing to animate', () {
      expect(
        resolvePreviewTransitionSpec(kind: 'cut_transition').isCut,
        isTrue,
      );
    });

    test('unknown / plugin kinds crossfade over their duration', () {
      for (final kind in ['move_transition', 'shader_transition', null]) {
        final spec = resolvePreviewTransitionSpec(
          kind: kind,
          duration: const Duration(milliseconds: 700),
        );
        expect(spec.kind, PreviewTransitionKind.fade, reason: '$kind');
        expect(spec.duration, const Duration(milliseconds: 700));
      }
    });

    test('a custom luma mask (only on the OBS machine) crossfades', () {
      final spec = resolvePreviewTransitionSpec(
        kind: 'wipe_transition',
        settings: {'luma_image': 'my-own-mask.png'},
      );
      expect(spec.kind, PreviewTransitionKind.fade);
    });

    test('stinger: cut at the transition point (ms or frames)', () {
      final ms = resolvePreviewTransitionSpec(
        kind: 'obs_stinger_transition',
        settings: {'transition_point': 850},
        duration: const Duration(milliseconds: 300),
      );
      expect(ms.kind, PreviewTransitionKind.cutAtEnd);
      expect(ms.stingerPoint, const Duration(milliseconds: 850));

      final frames = resolvePreviewTransitionSpec(
        kind: 'obs_stinger_transition',
        settings: {'transition_point': 30, 'tp_type': 1},
        fps: 60,
      );
      expect(frames.stingerPoint, const Duration(milliseconds: 500));

      /// Frame-based without a known frame rate - nothing to time it by
      final unknownFps = resolvePreviewTransitionSpec(
        kind: 'obs_stinger_transition',
        settings: {'transition_point': 30, 'tp_type': 1},
      );
      expect(unknownFps.isCut, isTrue);
    });
  });

  group('easing (plugins/obs-transitions)', () {
    test('cubicEaseInOut matches easings.h', () {
      expect(cubicEaseInOut(0), 0);
      expect(cubicEaseInOut(0.25), closeTo(0.0625, 1e-9));
      expect(cubicEaseInOut(0.5), closeTo(0.5, 1e-9));
      expect(cubicEaseInOut(0.75), closeTo(0.9375, 1e-9));
      expect(cubicEaseInOut(1), 1);
    });

    test('smoothstep handles a zero-width edge', () {
      expect(smoothstep(0, 0, 0.3), 1.0);
      expect(smoothstep(1, 1, 0.3), 0.0);
      expect(smoothstep(0, 1, 0.5), 0.5);
    });
  });

  group('PreviewTransitionTracker', () {
    late PreviewTransitionTracker tracker;
    late DateTime t0;
    DateTime at(int ms) => t0.add(Duration(milliseconds: ms));

    setUp(() {
      tracker = PreviewTransitionTracker();
      t0 = DateTime(2026, 10, 6, 12);
    });

    test('same scene frames are shown as they come', () {
      expect(
        tracker.frameArrived('A', _frame(1), at(0)),
        isA<ShowPreviewFrame>(),
      );
      expect(
        tracker.frameArrived('A', _frame(2), at(50)),
        isA<ShowPreviewFrame>(),
      );
    });

    test('a scene change without a transition cuts', () {
      tracker.frameArrived('A', _frame(1), at(0));
      final outcome = tracker.frameArrived('B', _frame(2), at(50));
      expect(outcome, isA<ShowPreviewFrame>());
      expect(tracker.shownScene, 'B');
    });

    test(
      'app switch: Started before the frame - animates from the old frame',
      () {
        tracker.frameArrived('A', _frame(1), at(0));
        tracker.appSwitchRequested('B', at(10));
        tracker.transitionStarted('Fade', at(13));
        expect(tracker.specResolved('Fade', null, _fade, at(20)), isNull);

        final outcome = tracker.frameArrived('B', _frame(2), at(60));
        expect(outcome, isA<StartPreviewTransition>());
        final start = outcome as StartPreviewTransition;
        expect(start.fromBytes, _frame(1));
        expect(start.toBytes, _frame(2));
        expect(start.spec.kind, PreviewTransitionKind.fade);

        /// Later frames of the new scene just show
        expect(
          tracker.frameArrived('B', _frame(3), at(90)),
          isA<ShowPreviewFrame>(),
        );
      },
    );

    test('elsewhere: frame held until target + spec resolve', () {
      tracker.frameArrived('A', _frame(1), at(0));
      tracker.transitionStarted('Swipe', at(5));

      /// activeSceneName already moved (program read applied) and the
      /// frame came before the spec
      tracker.targetResolved('B', at(15));
      expect(
        tracker.frameArrived('B', _frame(2), at(40)),
        isA<HoldPreviewFrame>(),
      );
      expect(tracker.isHolding, isTrue);

      /// A fresher frame of the held scene replaces the held one
      expect(
        tracker.frameArrived('B', _frame(3), at(70)),
        isA<HoldPreviewFrame>(),
      );

      final outcome = tracker.specResolved('Swipe', null, _fade, at(80));
      expect(outcome, isA<StartPreviewTransition>());
      expect((outcome as StartPreviewTransition).toBytes, _frame(3));
      expect(outcome.fromBytes, _frame(1));
      expect(tracker.isHolding, isFalse);
    });

    test('a hold that never resolves cuts at the deadline', () {
      tracker.frameArrived('A', _frame(1), at(0));
      tracker.transitionStarted('Swipe', at(5));
      tracker.targetResolved('B', at(15));
      tracker.frameArrived('B', _frame(2), at(40));

      expect(tracker.holdExpired(at(200)), isNull);
      final outcome = tracker.holdExpired(at(440));
      expect(outcome, isA<ShowPreviewFrame>());
      expect((outcome as ShowPreviewFrame).bytes, _frame(2));
      expect(tracker.shownScene, 'B');
    });

    test('a frame of a scene the transition does not go to cuts', () {
      tracker.frameArrived('A', _frame(1), at(0));
      tracker.appSwitchRequested('B', at(10));
      expect(
        tracker.frameArrived('C', _frame(2), at(40)),
        isA<ShowPreviewFrame>(),
      );
    });

    test('a cut transition shows the new frame directly', () {
      tracker.frameArrived('A', _frame(1), at(0));
      tracker.appSwitchRequested('B', at(10));
      tracker.transitionStarted('Cut', at(12));
      tracker.specResolved('Cut', null, PreviewTransitionSpec.none, at(14));
      final outcome = tracker.frameArrived('B', _frame(2), at(40));
      expect(outcome, isA<ShowPreviewFrame>());
      expect(tracker.shownScene, 'B');
    });

    test('stinger: the cut lands at its point after the start', () {
      tracker.frameArrived('A', _frame(1), at(0));
      tracker.appSwitchRequested('B', at(0));
      tracker.transitionStarted('Stinger', at(0));
      tracker.specResolved(
        'Stinger',
        null,
        const PreviewTransitionSpec(
          kind: PreviewTransitionKind.cutAtEnd,
          duration: Duration(milliseconds: 800),
          stingerPoint: Duration(milliseconds: 800),
        ),
        at(5),
      );
      final outcome = tracker.frameArrived('B', _frame(2), at(100));
      expect(
        (outcome as StartPreviewTransition).spec.duration,
        const Duration(milliseconds: 700),
      );
    });

    test('stinger point already passed when the frame arrives - show it', () {
      tracker.frameArrived('A', _frame(1), at(0));
      tracker.appSwitchRequested('B', at(0));
      tracker.transitionStarted('Stinger', at(0));
      tracker.specResolved(
        'Stinger',
        null,
        const PreviewTransitionSpec(
          kind: PreviewTransitionKind.cutAtEnd,
          duration: Duration(milliseconds: 50),
          stingerPoint: Duration(milliseconds: 50),
        ),
        at(5),
      );
      expect(
        tracker.frameArrived('B', _frame(2), at(100)),
        isA<ShowPreviewFrame>(),
      );
    });

    test('a stale last frame is no base for an animation', () {
      tracker.frameArrived('A', _frame(1), at(0));
      tracker.appSwitchRequested('B', at(5000));
      tracker.transitionStarted('Fade', at(5003));
      tracker.specResolved('Fade', null, _fade, at(5005));
      expect(
        tracker.frameArrived('B', _frame(2), at(5040)),
        isA<ShowPreviewFrame>(),
      );
    });

    test('an expired context no longer animates', () {
      tracker.frameArrived('A', _frame(1), at(0));
      tracker.appSwitchRequested('B', at(0));
      tracker.frameArrived('A', _frame(2), at(2000));
      tracker.frameArrived('A', _frame(3), at(3500));
      expect(
        tracker.frameArrived('B', _frame(4), at(3600)),
        isA<ShowPreviewFrame>(),
      );
    });

    test('disabled: always shows', () {
      tracker.frameArrived('A', _frame(1), at(0));
      tracker.appSwitchRequested('B', at(10));
      tracker.transitionStarted('Fade', at(12));
      tracker.specResolved('Fade', null, _fade, at(14));
      expect(
        tracker.frameArrived('B', _frame(2), at(40), animate: false),
        isA<ShowPreviewFrame>(),
      );
    });

    test('a frame of the old scene while holding drops the held frame', () {
      tracker.frameArrived('A', _frame(1), at(0));
      tracker.transitionStarted('Fade', at(5));
      tracker.targetResolved('B', at(10));
      tracker.frameArrived('B', _frame(2), at(30));
      final outcome = tracker.frameArrived('A', _frame(3), at(50));
      expect(outcome, isA<ShowPreviewFrame>());
      expect(tracker.isHolding, isFalse);
      expect(tracker.shownScene, 'A');
    });

    test('a spec resolved for another target is ignored', () {
      tracker.frameArrived('A', _frame(1), at(0));
      tracker.appSwitchRequested('C', at(0));
      tracker.transitionStarted('Fade', at(2));
      tracker.specResolved('Fade', 'B', _fade, at(4));
      expect(
        tracker.frameArrived('C', _frame(2), at(30)),
        isA<HoldPreviewFrame>(),
      );
      expect(
        tracker.specResolved('Fade', 'C', _fade, at(40)),
        isA<StartPreviewTransition>(),
      );
    });

    test('clearMeasurements forgets learned durations', () {
      tracker.transitionStarted('Quick', at(0));
      tracker.videoEnded('Quick', at(400));
      tracker.clearMeasurements();
      expect(tracker.measuredDuration('Quick'), isNull);
    });

    test('spec for another transition name is ignored', () {
      tracker.frameArrived('A', _frame(1), at(0));
      tracker.appSwitchRequested('B', at(0));
      tracker.transitionStarted('Fade', at(2));
      tracker.specResolved('Swipe', null, _fade, at(4));
      expect(
        tracker.frameArrived('B', _frame(2), at(30)),
        isA<HoldPreviewFrame>(),
      );
    });

    test('measures Started → VideoEnded per transition', () {
      tracker.transitionStarted('Quick', at(0));
      tracker.videoEnded('Quick', at(512));
      expect(
        tracker.measuredDuration('Quick'),
        const Duration(milliseconds: 512),
      );
      expect(tracker.measuredDuration('Other'), isNull);
    });

    test('reset forgets the shown frame and pending transitions', () {
      tracker.frameArrived('A', _frame(1), at(0));
      tracker.appSwitchRequested('B', at(0));
      tracker.reset();
      expect(tracker.shownScene, isNull);
      expect(
        tracker.frameArrived('B', _frame(2), at(10)),
        isA<ShowPreviewFrame>(),
      );
    });
  });
}
