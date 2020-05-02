import 'package:flutter/cupertino.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback onOk;
  final bool isYesDestructive;

  ConfirmationDialog(
      {@required this.title,
      @required this.body,
      @required this.onOk,
      this.isYesDestructive = false});

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
          child: Text('No'),
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
        CupertinoDialogAction(
          child: Text('Yes'),
          isDestructiveAction: true,
          onPressed: () {
            Navigator.of(context).pop();
            this.onOk();
          },
        ),
      ],
    );
  }
}
