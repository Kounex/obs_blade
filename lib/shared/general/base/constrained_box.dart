import 'package:flutter/material.dart';

const double kBaseConstrainedMaxWidth = 640.0;

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
      padding: this.padding ??
          EdgeInsets.symmetric(horizontal: this.hasBasePadding ? 24.0 : 0),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: this.maxWidth),
        child: this.child,
      ),
    );
  }
}
