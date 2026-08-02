import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import 'app_motion.dart';

/// Which glyph the [AnimatedResultIcon] draws
enum AnimatedResultType { positive, negative, missing }

/// Stroke-drawn result glyph (check / cross / question mark) capping
/// connect/purchase/action flows - the "On Air" signature moment for
/// `BaseResult`.
///
/// Draws a circle and the glyph over ~450ms with [AppMotion.emphasized]
/// plus an optional subtle scale settle. Plays once per widget lifecycle.
class AnimatedResultIcon extends StatefulWidget {
  final AnimatedResultType type;

  /// Diameter of the glyph box
  final double size;

  /// Stroke color - defaults to the ambient [IconTheme] color (same
  /// contract as [Icon.color])
  final Color? color;

  /// Subtle scale settle while drawing (default true)
  final bool settle;

  const AnimatedResultIcon({
    super.key,
    required this.type,
    this.size = 32.0,
    this.color,
    this.settle = true,
  });

  @override
  State<AnimatedResultIcon> createState() => _AnimatedResultIconState();
}

class _AnimatedResultIconState extends State<AnimatedResultIcon>
    with SingleTickerProviderStateMixin {
  static const Duration _kDrawDuration = Duration(milliseconds: 450);

  late final AnimationController _controller;
  late final Animation<double> _draw;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _kDrawDuration);
    _draw = CurvedAnimation(parent: _controller, curve: AppMotion.emphasized);
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color color = this.widget.color ??
        IconTheme.of(context).color ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        Widget icon = CustomPaint(
          size: Size.square(this.widget.size),
          painter: _ResultGlyphPainter(
            type: this.widget.type,
            color: color,
            progress: _draw.value,
          ),
        );
        if (this.widget.settle) {
          icon = Transform.scale(scale: _scale.value, child: icon);
        }
        return icon;
      },
    );
  }
}

class _ResultGlyphPainter extends CustomPainter {
  final AnimatedResultType type;
  final Color color;
  final double progress;

  /// Circle draws over the first ~60% of the animation, the glyph follows
  static const Interval _kCircleInterval = Interval(0.0, 0.62);
  static const Interval _kGlyphInterval = Interval(0.42, 1.0);

  _ResultGlyphPainter({
    required this.type,
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = math.max(2.0, size.width * 0.07);
    final Paint strokePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    /// All glyphs are designed in a 100x100 unit box
    final double unit = size.width / 100.0;
    canvas.save();
    canvas.scale(unit);

    final double circleProgress =
        _kCircleInterval.transform(progress).clamp(0.0, 1.0);
    final double glyphProgress =
        _kGlyphInterval.transform(progress).clamp(0.0, 1.0);

    _drawPartial(
      canvas,
      Path()
        ..addOval(Rect.fromCircle(
          center: const Offset(50.0, 50.0),
          radius: 44.0 - strokeWidth / unit / 2.0,
        )),
      circleProgress,
      strokePaint,
    );

    switch (this.type) {
      case AnimatedResultType.positive:
        _drawPartial(
          canvas,
          Path()
            ..moveTo(31.0, 52.0)
            ..lineTo(45.0, 66.0)
            ..lineTo(71.0, 37.0),
          glyphProgress,
          strokePaint,
        );
        break;
      case AnimatedResultType.negative:
        _drawPartial(
          canvas,
          Path()
            ..moveTo(34.0, 34.0)
            ..lineTo(66.0, 66.0)
            ..moveTo(66.0, 34.0)
            ..lineTo(34.0, 66.0),
          glyphProgress,
          strokePaint,
        );
        break;
      case AnimatedResultType.missing:
        _drawPartial(
          canvas,
          Path()
            ..moveTo(35.0, 38.0)
            ..cubicTo(35.0, 28.0, 42.0, 23.0, 50.0, 23.0)
            ..cubicTo(58.0, 23.0, 65.0, 28.0, 65.0, 36.0)
            ..cubicTo(65.0, 44.0, 58.0, 47.0, 53.0, 51.0)
            ..cubicTo(50.0, 54.0, 50.0, 57.0, 50.0, 61.0),
          glyphProgress,
          strokePaint,
        );

        /// Dot of the question mark - fades in with the glyph
        canvas.drawCircle(
          const Offset(50.0, 71.0),
          strokeWidth / unit / 2.0 + 1.0,
          Paint()
            ..color = color.withValues(alpha: glyphProgress)
            ..style = PaintingStyle.fill,
        );
        break;
    }

    canvas.restore();
  }

  /// Stroke only the leading [progress] fraction of [path]
  void _drawPartial(
      Canvas canvas, Path path, double progress, Paint paint) {
    if (progress <= 0.0) return;
    if (progress >= 1.0) {
      canvas.drawPath(path, paint);
      return;
    }
    final Path partial = Path();
    for (final PathMetric metric in path.computeMetrics()) {
      partial.addPath(
        metric.extractPath(0.0, metric.length * progress),
        Offset.zero,
      );
    }
    canvas.drawPath(partial, paint);
  }

  @override
  bool shouldRepaint(_ResultGlyphPainter oldDelegate) =>
      oldDelegate.progress != this.progress ||
      oldDelegate.color != this.color ||
      oldDelegate.type != this.type;
}
