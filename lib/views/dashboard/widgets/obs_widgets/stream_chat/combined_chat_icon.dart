import 'package:flutter/material.dart';

/// The combined chat mark — a speech bubble holding three chat lines in
/// the platforms' accent colors (Twitch purple, Kick green, YouTube red):
/// several chats in one. Painted from the source SVG
/// (`docs/combined-chat-icon.svg`, 24×24 viewBox) so no SVG dependency is
/// needed; the lines keep their fixed colors, the bubble follows the
/// theme so it never sinks into a dark surface.
class CombinedChatIcon extends StatelessWidget {
  final double size;

  /// Bubble fill — defaults to a theme-aware neutral (the source's
  /// `#3a3a44` on light surfaces, a lifted gray on dark ones).
  final Color? bubbleColor;

  const CombinedChatIcon({super.key, this.size = 24.0, this.bubbleColor});

  static const Color kTwitchLine = Color(0xFFB58CF0);
  static const Color kKickLine = Color(0xFF5FC27E);
  static const Color kYouTubeLine = Color(0xFFF07F78);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'Combined chat',
      child: SizedBox.square(
        dimension: this.size,
        child: CustomPaint(
          painter: _CombinedChatPainter(
            bubble:
                this.bubbleColor ??
                (dark ? const Color(0xFF55555F) : const Color(0xFF3A3A44)),
          ),
        ),
      ),
    );
  }
}

class _CombinedChatPainter extends CustomPainter {
  final Color bubble;

  const _CombinedChatPainter({required this.bubble});

  /// `M5 3h14a2 2 0 0 1 2 2v11a2 2 0 0 1-2 2h-8l-4 3.5V18H5a2 2 0 0 1-2-2
  /// V5a2 2 0 0 1 2-2z` — rounded rect with a tail from its bottom edge.
  static Path _bubble() {
    const r = Radius.circular(2.0);
    return Path()
      ..moveTo(5, 3)
      ..lineTo(19, 3)
      ..arcToPoint(const Offset(21, 5), radius: r)
      ..lineTo(21, 16)
      ..arcToPoint(const Offset(19, 18), radius: r)
      ..lineTo(11, 18)
      ..lineTo(7, 21.5)
      ..lineTo(7, 18)
      ..lineTo(5, 18)
      ..arcToPoint(const Offset(3, 16), radius: r)
      ..lineTo(3, 5)
      ..arcToPoint(const Offset(5, 3), radius: r)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24.0, size.height / 24.0);
    canvas.drawPath(_bubble(), Paint()..color = this.bubble);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      const Offset(7.5, 7.5),
      const Offset(16.5, 7.5),
      line..color = CombinedChatIcon.kTwitchLine,
    );
    canvas.drawLine(
      const Offset(7.5, 10.5),
      const Offset(13.5, 10.5),
      line..color = CombinedChatIcon.kKickLine,
    );
    canvas.drawLine(
      const Offset(7.5, 13.5),
      const Offset(15.5, 13.5),
      line..color = CombinedChatIcon.kYouTubeLine,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CombinedChatPainter oldDelegate) =>
      oldDelegate.bubble != this.bubble;
}

/// A chat type's icon widget: the multi-color [CombinedChatIcon] for
/// Combined, the font glyph (tinted [color]) for every platform.
Widget chatTypeIcon(
  BuildContext context,
  IconData glyph, {
  required bool combined,
  Color? color,
  double size = 24.0,
}) => combined
    ? CombinedChatIcon(size: size)
    : Icon(glyph, color: color, size: size);
