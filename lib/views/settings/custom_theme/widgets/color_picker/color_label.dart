import 'package:flutter/material.dart';

class ColorLabel extends StatelessWidget {
  final String label;
  final double width;

  const ColorLabel({
    super.key,
    required this.label,
    this.width = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: this.width,
      child: Text(
        this.label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
