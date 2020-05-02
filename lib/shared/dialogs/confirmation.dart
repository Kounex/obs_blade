import 'package:flutter/cupertino.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback onOk;

  ConfirmationDialog(
      {@required this.title, @required this.body, @required this.onOk});

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Text(this.title),
      ),
      content: Text(this.body),
      actions: [
        CupertinoDialogAction(
          child: Text('Yes'),
          isDestructiveAction: true,
          onPressed: this.onOk,
        ),
        CupertinoDialogAction(
          child: Text('No'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
