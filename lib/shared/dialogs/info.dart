import 'package:flutter/cupertino.dart';

class InfoDialog extends StatelessWidget {
  final String? title;
  final String body;

  final VoidCallback? onPressed;

  const InfoDialog({
    Key? key,
    required this.body,
    this.title,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: this.title != null
          ? Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(this.title!),
            )
          : null,
      content: Text(
        this.body,
        textAlign: TextAlign.center,
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('OK'),
          isDefaultAction: false,
          onPressed: () {
            this.onPressed?.call();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
