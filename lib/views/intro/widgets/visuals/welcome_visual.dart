import 'dart:math';

import 'package:flutter/material.dart';
import 'package:obs_blade/shared/design/design.dart';

import '../../../../shared/general/social_block.dart';
import '../../../../shared/general/themed/rich_text.dart';
import '../../../../utils/styling_helper.dart';
import '../intro_page.dart';

/// Welcome brand art: the OBS Blade vortex mark slowly turning inside
/// breathing accent rings, the wordmark underneath. Built from the existing
/// brand PNGs - the rings and glow are drawn in code
class WelcomeVisual extends IntroVisual {
  const WelcomeVisual({super.key, required super.active});

  @override
  State<WelcomeVisual> createState() => _WelcomeVisualState();
}

class _WelcomeVisualState extends IntroLoopState<WelcomeVisual> {
  @override
  Duration get period => const Duration(seconds: 12);

  @override
  double get restValue => 0.0;

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).buttonTheme.colorScheme!.secondary;
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 360.0,
      height: 400.0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StaggeredEntrance(
            scaleFrom: 0.9,
            duration: AppMotion.dramatic,
            child: SizedBox(
              width: 240.0,
              height: 240.0,
              child: AnimatedBuilder(
                animation: loop,
                builder: (context, _) {
                  final double t = loop.value;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size.square(240.0),
                        painter: _RingsPainter(
                          t: t,
                          accent: accent,
                          dark: dark,
                        ),
                      ),
                      Container(
                        width: 132.0,
                        height: 132.0,
                        decoration: ShapeDecoration(
                          color: Color.alphaBlend(
                            accent.withValues(alpha: 0.12),
                            Theme.of(context).cardColor,
                          ),
                          shape: ContinuousRectangleBorder(
                            borderRadius: BorderRadius.circular(132.0 * 0.38),
                            side: BorderSide(color: accent, width: 1.5),
                          ),
                          shadows: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.35),
                              blurRadius: 36.0,
                              spreadRadius: -6.0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Transform.rotate(
                            angle: -t * 2 * pi,
                            child: Image.asset(
                              'assets/images/logo_vortex.png',
                              width: 76.0,
                              height: 76.0,
                              color: accent,
                              colorBlendMode: BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          StaggeredEntrance(
            index: 2,
            child: Image.asset(
              StylingHelper.brightnessAwareOBSLogo(context),
              width: 150.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Concentric rings around the mark: two arcs sweeping in opposite
/// directions plus a breathing halo
class _RingsPainter extends CustomPainter {
  final double t;
  final Color accent;
  final bool dark;

  _RingsPainter({required this.t, required this.accent, required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double breathe = (sin(t * 2 * pi * 3) + 1) / 2;

    canvas.drawCircle(
      center,
      size.width * 0.36 + breathe * 6.0,
      Paint()
        ..shader = RadialGradient(
          colors: [
            accent.withValues(alpha: 0.18 + breathe * 0.06),
            accent.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: size.width / 2)),
    );

    void ring(double radius, double alpha, double width) => canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = accent.withValues(alpha: alpha),
    );

    ring(size.width * 0.38, 0.14, 1.0);
    ring(size.width * 0.48, 0.08, 1.0);

    void arc(double radius, double start, double sweep, double alpha) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            startAngle: start,
            endAngle: start + sweep,
            colors: [
              accent.withValues(alpha: 0.0),
              accent.withValues(alpha: alpha),
            ],
            transform: GradientRotation(0.0),
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    arc(size.width * 0.38, t * 2 * pi * 2, pi * 0.9, 0.9);
    arc(size.width * 0.48, -t * 2 * pi * 1.5 + pi, pi * 0.6, 0.55);
  }

  @override
  bool shouldRepaint(_RingsPainter oldDelegate) =>
      oldDelegate.t != this.t ||
      oldDelegate.accent != this.accent ||
      oldDelegate.dark != this.dark;
}

/// "Unofficial, open source · built on obs-websocket" small print with the
/// two links, under the welcome copy
class WelcomeFootnote extends StatelessWidget {
  const WelcomeFootnote({super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle style = Theme.of(context).textTheme.bodySmall!.copyWith(
      color: Theme.of(context).extension<AppTextColors>()!.textTertiary,
    );

    WidgetSpan link(String text, String url) => WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: SocialBlock(
        topPadding: 0,
        bottomPadding: 0,
        socialInfos: [SocialEntry(linkText: text, link: url, textStyle: style)],
      ),
    );

    return ThemedRichText(
      textAlign: TextAlign.center,
      textStyle: style,
      textSpans: [
        const TextSpan(text: 'Unofficial and '),
        link('open source', 'https://github.com/Kounex/obs_blade'),
        const TextSpan(text: ' · built on '),
        link('obs-websocket', 'https://github.com/obsproject/obs-websocket'),
      ],
    );
  }
}
