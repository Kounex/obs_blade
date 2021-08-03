import 'package:flutter/material.dart';

class ColorLabel extends StatelessWidget {
  final String label;
  final double width;

  const ColorLabel({
    Key? key,
    required this.label,
    this.width = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: this.width,
      child: Text(
        this.label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headline6,
      ),
    );
  }
}
