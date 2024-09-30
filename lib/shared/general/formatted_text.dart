import 'package:flutter/material.dart';

class FormattedText extends StatelessWidget {
  final String label;
  final String? text;
  final double width;
  final String? unit;

  const FormattedText({
    super.key,
    required this.label,
    this.text,
    this.width = 50.0,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: this.width,
      child: TextField(
        controller: TextEditingController(
          text:
              (this.text ?? '-') + (this.text != null ? (this.unit ?? '') : ''),
        ),
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
          fontFeatures: [
            const FontFeature.tabularFigures(),
          ],
        ),
        decoration: InputDecoration(
          isDense: true,
          enabled: false,
          labelText: this.label,
          labelStyle:
              Theme.of(context).textTheme.bodyMedium!.copyWith(height: 0.75),
        ),
      ),
    );
  }
}
