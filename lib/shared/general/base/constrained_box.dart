import 'package:flutter/material.dart';

/// Readable measure for text / list screens (settings rows, forms, FAQ)
/// on wide screens - also every [BaseCard]'s default cap.
const double kBaseConstrainedMaxWidth = 720.0;

/// Wide tier for data-dense screens (charts, stat grids) on tablets, where
/// the reading measure would leave the content cramped.
const double kWideContentMaxWidth = 1040.0;

class BaseConstrainedBox extends StatelessWidget {
  final Widget? child;

  final double maxWidth;

  final bool hasBasePadding;

  final EdgeInsetsGeometry? padding;

  const BaseConstrainedBox({
    super.key,
    required this.child,
    this.maxWidth = kBaseConstrainedMaxWidth,
    this.hasBasePadding = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          this.padding ??
          EdgeInsets.symmetric(horizontal: this.hasBasePadding ? 24.0 : 0),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: this.maxWidth),
        child: this.child,
      ),
    );
  }
}
