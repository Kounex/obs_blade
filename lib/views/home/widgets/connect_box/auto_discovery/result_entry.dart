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

          /// Callout scale for the explanatory copy - readable line height
          /// for multi-line error states
          textStyle:
              Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5),
          textSpans: [
            TextSpan(text: this.result),
            TextSpan(
              text: '\n\nPull down to try again!',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
