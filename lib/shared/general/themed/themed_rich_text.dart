import 'package:flutter/material.dart';

class ThemedRichText extends StatelessWidget {
  final List<InlineSpan> textSpans;
  final TextAlign? textAlign;
  final TextStyle? textStyle;

  const ThemedRichText({
    Key? key,
    required this.textSpans,
    this.textAlign,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: this.textAlign ?? TextAlign.start,
      text: TextSpan(
        style: this.textStyle ?? Theme.of(context).textTheme.bodyText2,
        children: this.textSpans,
      ),
    );
  }
}
