import 'package:flutter/material.dart';

class BaseDivider extends StatelessWidget {
  final double? height;

  const BaseDivider({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: Theme.of(context).dividerColor.withOpacity(0.4),
      height: this.height ?? 1.0,
      thickness: 0.0,
    );
  }
}
