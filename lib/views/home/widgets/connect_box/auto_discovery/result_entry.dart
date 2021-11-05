import 'package:flutter/material.dart';
import 'package:obs_blade/shared/animator/fader.dart';
import 'package:obs_blade/shared/general/themed/rich_text.dart';

class ResultEntry extends StatelessWidget {
  final String result;

  const ResultEntry({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      alignment: Alignment.center,
      child: Fader(
        child: ThemedRichText(
          textAlign: TextAlign.center,
          textSpans: [
            TextSpan(text: this.result),
            const TextSpan(
              text: '\n\nPull down to try again!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
