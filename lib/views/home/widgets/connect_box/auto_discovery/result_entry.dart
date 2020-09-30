import 'package:flutter/material.dart';
import 'package:obs_blade/shared/animator/fader.dart';
import 'package:obs_blade/shared/general/themed/themed_rich_text.dart';

class ResultEntry extends StatelessWidget {
  final String result;

  ResultEntry({@required this.result}) : assert(result != null);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.0),
      alignment: Alignment.center,
      child: Fader(
        child: ThemedRichText(
          textAlign: TextAlign.center,
          textSpans: [
            TextSpan(text: '${this.result}'),
            TextSpan(
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
