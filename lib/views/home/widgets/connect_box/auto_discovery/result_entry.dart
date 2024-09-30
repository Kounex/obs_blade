import 'package:flutter/material.dart';

import '../../../../../shared/animator/fader.dart';
import '../../../../../shared/general/themed/rich_text.dart';

class ResultEntry extends StatelessWidget {
  final String result;

  const ResultEntry({super.key, required this.result});

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
