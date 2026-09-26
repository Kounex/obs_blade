import 'dart:math';

import 'package:flutter/material.dart';
import 'package:obs_blade/shared/design/design.dart';

import '../../../../shared/general/social_block.dart';
import '../../../../shared/general/themed/rich_text.dart';
import '../intro_page.dart';

/// Welcome brand art: the OBS Blade vortex mark slowly turning on a soft
/// neutral disc inside breathing accent rings. The mark is the existing
/// brand PNG - disc, rings and glow are drawn in code
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

    /// Neutral disc behind the mark - same white / black 7 % idiom as the
    /// decorative icon tiles, fading out radially instead of a hard edge
    final Color disc = (dark ? Colors.white : Colors.black).withValues(
      alpha: dark ? 0.08 : 0.06,
    );

    return StaggeredEntrance(
      scaleFrom: 0.9,
      duration: AppMotion.dramatic,
      child: SizedBox(
        width: 300.0,
        height: 300.0,
        child: AnimatedBuilder(
          animation: loop,
          builder: (context, _) {
            final double t = loop.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size.square(300.0),
                  painter: _RingsPainter(t: t, accent: accent),
                ),
                Container(
                  width: 176.0,
                  height: 176.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [disc, disc, disc.withValues(alpha: 0.0)],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                  child: Center(
                    /// Circular clip, inset past the bitmap edge: a rotated
                    /// bitmap's transparent border otherwise resamples into
                    /// a faint hairline on device (the mark's outer ring
                    /// ends at ~92 % radius)
                    child: ClipOval(
                      clipper: const _InsetOvalClipper(2.0),
                      child: Transform.rotate(
                        angle: -t * 2 * pi,
                        filterQuality: FilterQuality.medium,
                        child: Image.asset(
                          'assets/images/logo_vortex.png',
                          width: 96.0,
                          height: 96.0,
                          color: accent,
                          colorBlendMode: BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Oval clip deflated by [inset] on every side
class _InsetOvalClipper extends CustomClipper<Rect> {
  final double inset;

  const _InsetOvalClipper(this.inset);

  @override
  Rect getClip(Size size) => (Offset.zero & size).deflate(this.inset);

  @override
  bool shouldReclip(_InsetOvalClipper oldClipper) =>
      oldClipper.inset != this.inset;
}

/// Rings around the mark: two faint guide circles, a breathing halo and
/// two comet arcs orbiting in opposite directions. Every motion completes
/// whole cycles per loop (arcs 2 / -1 turns, halo 3 breaths), so the loop
/// wraps seamlessly; each arc fades in at its tail AND out at its head,
/// so neither end shows a hard stop
class _RingsPainter extends CustomPainter {
  final double t;
  final Color accent;

  _RingsPainter({required this.t, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double breathe = (sin(t * 2 * pi * 3) + 1) / 2;

    canvas.drawCircle(
      center,
      size.width / 2,
      Paint()
        ..shader = RadialGradient(
          colors: [
            accent.withValues(alpha: 0.16 + breathe * 0.06),
            accent.withValues(alpha: 0.0),
          ],
          stops: [0.0, 0.72 + breathe * 0.06],
        ).createShader(Rect.fromCircle(center: center, radius: size.width / 2)),
    );

    void ring(double radius, double alpha) => canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = accent.withValues(alpha: alpha),
    );

    ring(size.width * 0.36, 0.12);
    ring(size.width * 0.46, 0.07);

    /// The gradient is laid out from angle 0 and rotated into place -
    /// sweep angles past 2 pi would clamp and draw a visible seam
    void arc(double radius, double start, double sweep, double alpha) {
      final Rect rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..shader = SweepGradient(
            endAngle: sweep,
            colors: [
              accent.withValues(alpha: 0.0),
              accent.withValues(alpha: alpha),
              accent.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.78, 1.0],
            transform: GradientRotation(start),
          ).createShader(rect),
      );
    }

    arc(size.width * 0.36, t * 2 * pi * 2, pi * 0.9, 0.9);
    arc(size.width * 0.46, -t * 2 * pi + pi, pi * 0.6, 0.55);
  }

  @override
  bool shouldRepaint(_RingsPainter oldDelegate) =>
      oldDelegate.t != this.t || oldDelegate.accent != this.accent;
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
