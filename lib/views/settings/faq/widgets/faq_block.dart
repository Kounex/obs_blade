import 'package:flutter/material.dart';

class FAQBlock extends StatelessWidget {
  final String heading;
  final String? text;
  final Widget? customBody;

  const FAQBlock({
    Key? key,
    required this.heading,
    this.text,
    this.customBody,
  })  : assert(text != null || customBody != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          this.heading,
          style: TextStyle(
            fontSize: Theme.of(context).textTheme.titleLarge!.fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        this.text != null ? Text(this.text!) : this.customBody!,
      ],
    );
  }
}
