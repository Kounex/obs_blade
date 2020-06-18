import 'package:flutter/material.dart';

class FormattedText extends StatelessWidget {
  final String label;
  final String text;
  final double width;

  FormattedText({@required this.label, this.text, this.width = 50.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: this.width,
      child: TextField(
        controller: TextEditingController(text: this.text ?? '-'),
        decoration: InputDecoration(enabled: false, labelText: this.label),
      ),
    );
  }
}
