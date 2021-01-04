import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ConfirmationDialog extends StatefulWidget {
  final String title;
  final String body;
  final void Function(bool) onOk;
  final bool isYesDestructive;

  final String okText;
  final String noText;

  final bool enableDontShowAgainOption;

  ConfirmationDialog({
    @required this.title,
    @required this.body,
    @required this.onOk,
    this.isYesDestructive = false,
    this.okText = 'Yes',
    this.noText = 'No',
    this.enableDontShowAgainOption = false,
  });

  @override
  _ConfirmationDialogState createState() => _ConfirmationDialogState();
}

class _ConfirmationDialogState extends State<ConfirmationDialog> {
  bool _dontShowChecked = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(this.widget.title),
      ),
      content: Column(
        children: [
          Text(this.widget.body),
          if (this.widget.enableDontShowAgainOption)
            Padding(
              padding: const EdgeInsets.only(top: 14.0),
              child: Transform.translate(
                offset: Offset(-8, 0),
                child: Row(
                  children: [
                    Material(
                      type: MaterialType.transparency,
                      child: Checkbox(
                        value: _dontShowChecked,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (checked) =>
                            setState(() => _dontShowChecked = checked),
                      ),
                    ),
                    Text('Don\'t show this again'),
                  ],
                ),
              ),
            ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          child: Text(this.widget.noText),
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
        CupertinoDialogAction(
          child: Text(this.widget.okText),
          isDestructiveAction: this.widget.isYesDestructive,
          onPressed: () {
            Navigator.of(context).pop();
            this.widget.onOk(_dontShowChecked);
          },
        ),
      ],
    );
  }
}
