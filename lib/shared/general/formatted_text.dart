import 'package:flutter/material.dart';

class FormattedText extends StatelessWidget {
  final String label;
  final String? text;
  final double width;
  final String? unit;

  FormattedText({
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
        decoration: InputDecoration(
          isDense: true,
          enabled: false,
          labelText: this.label,
          labelStyle: TextStyle(height: 0.75),
        ),
      ),
    );
  }
}
