import 'package:flutter/material.dart';

/// Small circular color swatch.
///
/// (Semi-)transparent colors are backed by a checkerboard - the universal
/// transparency metaphor - so e.g. an unset (transparent) card border
/// color stays visible instead of blending into the surrounding surface.
class ColorBubble extends StatelessWidget {
  final Color color;
  final double size;

  const ColorBubble({super.key, required this.color, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: this.size,
      width: this.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(this.size / 2),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(this.size / 2),
        child: CustomPaint(
          painter: this.color.a < 1.0 ? const _CheckerboardPainter() : null,
          child: Container(color: this.color),
        ),
      ),
    );
  }
}

/// Paints the classic light grey checkerboard used by image editors to
/// visualise transparency.
class _CheckerboardPainter extends CustomPainter {
  const _CheckerboardPainter();

  static const double _squareSize = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint light = Paint()..color = const Color(0xFFFFFFFF);
    final Paint dark = Paint()..color = const Color(0xFFBDBDBD);

    canvas.drawRect(Offset.zero & size, light);
    for (double y = 0; y < size.height; y += _squareSize) {
      for (double x = 0; x < size.width; x += _squareSize) {
        if (((x / _squareSize).floor() + (y / _squareSize).floor()).isEven) {
          canvas.drawRect(
            Rect.fromLTWH(x, y, _squareSize, _squareSize),
            dark,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckerboardPainter oldDelegate) => false;
}
