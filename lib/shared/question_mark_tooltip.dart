import 'package:flutter/material.dart';

class QuestionMarkTooltip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          'Password is optional. You have to set it manually in the OBS WebSocket Plugin. It is highly recommended!',
      child: Icon(Icons.help_outline),
    );
  }
}
