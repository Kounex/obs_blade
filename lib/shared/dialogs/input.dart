import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class InputDialog extends StatefulWidget {
  final String title;
  final String body;

  final String inputPlaceholder;
  final ValueChanged<String> onSave;

  InputDialog(
      {@required this.title,
      @required this.body,
      @required this.onSave,
      this.inputPlaceholder});

  @override
  _InputDialogState createState() => _InputDialogState();
}

class _InputDialogState extends State<InputDialog> {
  TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Text(widget.title),
      ),
      content: Column(
        children: [
          Text(widget.body),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: CupertinoTextField(
              controller: _controller,
              placeholder: widget.inputPlaceholder,
            ),
          ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          child: Text('Cancel'),
          isDestructiveAction: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
        CupertinoDialogAction(
          child: Text('Save'),
          onPressed: () {
            Navigator.of(context).pop();
            widget.onSave(_controller.text);
          },
        ),
      ],
    );
  }
}
