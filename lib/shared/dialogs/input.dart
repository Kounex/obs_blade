import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class InputDialog extends StatefulWidget {
  final String title;
  final String body;

  final String inputPlaceholder;
  final void Function(String) onSave;

  /// Works like validation - return an empty String to tell its valid and otherwise
  /// the error text which should be displayed (prevents the 'Ok' dialog callback)
  final String Function(String) inputCheck;

  InputDialog({
    @required this.title,
    @required this.body,
    @required this.onSave,
    this.inputPlaceholder,
    this.inputCheck,
  });

  @override
  _InputDialogState createState() => _InputDialogState();
}

class _InputDialogState extends State<InputDialog> {
  TextEditingController _controller = TextEditingController();
  String _validationText = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
              controller: _controller
                ..addListener(() =>
                    _validationText = widget.inputCheck(_controller.text)),
              placeholder: widget.inputPlaceholder,
            ),
          ),
          Text(
            _validationText,
            style: TextStyle(
              color: Colors.red,
            ),
          )
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
            if (_validationText == null || _validationText.length == 0) {
              Navigator.of(context).pop();
              widget.onSave(_controller.text);
            }
          },
        ),
      ],
    );
  }
}
