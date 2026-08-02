import 'package:flutter/cupertino.dart';

import '../../../../shared/design/design.dart';
import '../../../../shared/general/base/card.dart';

class IconClipper extends CustomClipper<Path> {
  final double xCut;
  final double yCut;

  final double borderRadius;

  IconClipper({
    required this.xCut,
    required this.yCut,
    this.borderRadius = 4.0,
  });

  @override
  Path getClip(Size size) => Path()
    ..moveTo(0.0, this.yCut)
    ..lineTo(size.width - (this.xCut + this.borderRadius), this.yCut)
    ..quadraticBezierTo(size.width - this.xCut, this.yCut,
        size.width - this.xCut, (this.yCut + this.borderRadius))
    ..lineTo(size.width - this.xCut, size.height)
    ..lineTo(0.0, size.height)
    ..close();

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

class HeaderDecoration extends StatefulWidget {
  final IconData? icon;
  final double iconSize;

  final double iconXOffset;
  final double iconYOffset;

  final double iconXCut;
  final double iconYCut;
  final double iconCornerRadius;

  const HeaderDecoration({
    super.key,
    this.icon = CupertinoIcons.chart_pie_fill,
    this.iconSize = 128.0,
    this.iconXOffset = 28.0,
    this.iconYOffset = -42.0,
    this.iconXCut = 28.0,
    this.iconYCut = 42.0,
    this.iconCornerRadius = kBaseCardBorderRadius,
  });

  @override
  State<HeaderDecoration> createState() => _HeaderDecorationState();
}

class _HeaderDecorationState extends State<HeaderDecoration>
    with SingleTickerProviderStateMixin {
  /// One-shot entrance for the decorative watermark icon (fade + settle) -
  /// no perpetual drift on a static screen
  late final AnimationController _entranceController;
  late final Animation<double> _entrance;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    );
    _entrance = CurvedAnimation(
      parent: _entranceController,
      curve: AppMotion.emphasized,
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(
        this.widget.iconXOffset,
        this.widget.iconYOffset,
      ),
      child: ClipPath(
        clipper: IconClipper(
          xCut: this.widget.iconXCut,
          yCut: this.widget.iconYCut,
          borderRadius: this.widget.iconCornerRadius,
        ),
        clipBehavior: Clip.antiAlias,
        child: AnimatedBuilder(
          animation: _entrance,
          builder: (context, child) => Opacity(
            opacity: _entrance.value,
            child: Transform.translate(
              offset: Offset(0.0, 6.0 * (1.0 - _entrance.value)),
              child: child,
            ),
          ),
          child: Icon(
            this.widget.icon ?? CupertinoIcons.chart_pie_fill,
            size: this.widget.iconSize,
            color: IconTheme.of(context).color?.withValues(alpha: 0.20),
          ),
        ),
      ),
    );
  }
}
