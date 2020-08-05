import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class InfoDialog extends StatelessWidget {
  final String body;

  InfoDialog({@required this.body});

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      content: Text(
        this.body,
        textAlign: TextAlign.center,
      ),
      actions: [
        CupertinoDialogAction(
          child: Text('OK'),
          isDefaultAction: false,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
