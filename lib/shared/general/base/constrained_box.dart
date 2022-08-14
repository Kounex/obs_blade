import 'package:flutter/material.dart';

const double kBaseConstrainedMaxWidth = 640.0;

class BaseConstrainedBox extends StatelessWidget {
  final Widget? child;

  final double maxWidth;

  const BaseConstrainedBox({
    super.key,
    required this.child,
    this.maxWidth = kBaseConstrainedMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: this.maxWidth),
      child: this.child,
    );
  }
}
