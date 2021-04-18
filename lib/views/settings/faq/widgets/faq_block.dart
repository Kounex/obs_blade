import 'package:flutter/material.dart';

class FAQBlock extends StatelessWidget {
  final String heading;
  final String? text;
  final Widget? customBody;

  FAQBlock({
    required this.heading,
    this.text,
    this.customBody,
  }) : assert(text != null || customBody != null);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          this.heading,
          style: TextStyle(
            fontSize: Theme.of(context).textTheme.headline6!.fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.0),
        this.text != null ? Text(this.text!) : this.customBody!,
      ],
    );
  }
}
