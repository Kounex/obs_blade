import 'package:flutter/material.dart';

class ThemedRichText extends StatelessWidget {
  final List<InlineSpan> textSpans;
  final TextAlign? textAlign;
  final TextStyle? textStyle;

  const ThemedRichText({
    super.key,
    required this.textSpans,
    this.textAlign,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: this.textAlign ?? TextAlign.start,
      text: TextSpan(
        style: this.textStyle ?? DefaultTextStyle.of(context).style,
        children: this.textSpans,
      ),
    );
  }
}
