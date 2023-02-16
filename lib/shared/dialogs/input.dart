import 'package:flutter/cupertino.dart';

import '../general/validation_cupertino_textfield.dart';

class InputDialog extends StatefulWidget {
  final String title;
  final String body;

  final String? inputText;
  final String? inputPlaceholder;
  final void Function(String?) onSave;

  /// Works like validation - return an empty String to tell it is valid and otherwise
  /// the error text which should be displayed (prevents the 'Ok' dialog callback)
  final String? Function(String)? inputCheck;

  const InputDialog({
    Key? key,
    required this.title,
    required this.body,
    required this.onSave,
    this.inputText,
    this.inputPlaceholder,
    this.inputCheck,
  }) : super(key: key);

  @override
  _InputDialogState createState() => _InputDialogState();
}

class _InputDialogState extends State<InputDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    _controller = this.widget.inputCheck != null
        ? CustomValidationTextEditingController(
            text: this.widget.inputText ?? '',
            check: this.widget.inputCheck!,
          )
        : TextEditingController(
            text: this.widget.inputText ?? '',
          );
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
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(this.widget.title),
      ),
      content: Column(
        children: [
          Text(this.widget.body),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: this.widget.inputCheck != null
                ? ValidationCupertinoTextfield(
                    controller:
                        _controller as CustomValidationTextEditingController,
                    placeholder: this.widget.inputPlaceholder,
                  )
                : CupertinoTextField(
                    controller: _controller,
                    placeholder: this.widget.inputPlaceholder,
                  ),
          ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          child: const Text('Save'),
          onPressed: () {
            bool valid = true;
            if (this.widget.inputCheck != null) {
              (_controller as CustomValidationTextEditingController).submit();
              valid = (_controller as CustomValidationTextEditingController)
                  .isValid;
            }
            if (valid) {
              this
                  .widget
                  .onSave(_controller.text.isEmpty ? null : _controller.text);
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}
