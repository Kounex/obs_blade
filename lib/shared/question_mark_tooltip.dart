import 'package:flutter/material.dart';

class QuestionMarkTooltip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          'Password is optional. You have to set it manually in the OBS WebSocket Plugin. It is highly recommended though!',
      padding: EdgeInsets.all(12.0),
      margin: EdgeInsets.all(32.0),
      preferBelow: false,
      verticalOffset: 16.0,
      showDuration: Duration(seconds: 5),
      child: Icon(Icons.help_outline),
    );
  }
}
