import 'package:flutter/material.dart';
import 'package:obs_station/utils/styling_helper.dart';

class QuestionMarkTooltip extends StatelessWidget {
  final String message;

  QuestionMarkTooltip({@required this.message});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: this.message,
      padding: EdgeInsets.all(12.0),
      margin: EdgeInsets.all(32.0),
      preferBelow: false,
      verticalOffset: 16.0,
      showDuration: Duration(seconds: 5),
      child: Icon(StylingHelper.CUPERTINO_QUESTION_ICON),
    );
  }
}
