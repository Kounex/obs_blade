import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/validation_cupertino_textfield.dart';

class InputDialog extends StatefulWidget {
  final String title;
  final String body;

  final String inputText;
  final String inputPlaceholder;
  final bool inputAutocorrect;
  final void Function(String) onSave;

  /// Works like validation - return an empty String to tell it is valid and otherwise
  /// the error text which should be displayed (prevents the 'Ok' dialog callback)
  final String Function(String) inputCheck;

  InputDialog({
    @required this.title,
    @required this.body,
    this.inputAutocorrect = true,
    @required this.onSave,
    this.inputText,
    this.inputPlaceholder,
    this.inputCheck,
  });

  @override
  _InputDialogState createState() => _InputDialogState();
}

class _InputDialogState extends State<InputDialog> {
  GlobalKey<ValidationCupertinoTextfieldState> _validationKey = GlobalKey();
  TextEditingController _controller;

  @override
  void initState() {
    _controller = TextEditingController(text: widget.inputText ?? '');
    super.initState();
  }

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
            child: ValidationCupertinoTextfield(
              key: _validationKey,
              controller: _controller..addListener(() => setState(() {})),
              placeholder: widget.inputPlaceholder,
              autocorrect: widget.inputAutocorrect,
              check: widget.inputCheck,
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
        Builder(
          builder: (context) => CupertinoDialogAction(
            child: Text('Save'),
            onPressed: _validationKey.currentState.isValid
                ? () {
                    if (_validationKey.currentState.isValid) {
                      widget.onSave(_controller.text);
                      Navigator.of(context).pop();
                    }
                  }
                : null,
          ),
        ),
      ],
    );
  }
}
