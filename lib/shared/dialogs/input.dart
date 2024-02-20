import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/base/adaptive_dialog/adaptive_dialog.dart';

import '../general/base/adaptive_text_field.dart';

class InputDialog extends StatefulWidget {
  final String title;
  final String body;

  final String? inputText;
  final String? inputPlaceholder;
  final void Function(String?) onSave;

  /// Works like validation - return an empty String to tell it is valid and otherwise
  /// the error text which should be displayed (prevents the 'Ok' dialog callback)
  final String? Function(String?)? inputCheck;

  const InputDialog({
    Key? key,
    required this.title,
    required this.body,
    required this.onSave,
    this.inputText,
    this.inputPlaceholder,
    this.inputCheck,
  });

  @override
  _InputDialogState createState() => _InputDialogState();
}

class _InputDialogState extends State<InputDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  late final TextEditingController _controller;

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
    return BaseAdaptiveDialog(
      title: this.widget.title,
      bodyWidget: Column(
        children: [
          Text(this.widget.body),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Form(
              key: _formKey,
              child: BaseAdaptiveTextField(
                controller:
                    _controller as CustomValidationTextEditingController,
                placeholder: this.widget.inputPlaceholder,
              ),
            ),
          ),
        ],
      ),
      actions: [
        DialogActionConfig(
          isDestructiveAction: true,
          child: const Text('Cancel'),
        ),
        DialogActionConfig(
          child: const Text('Save'),
          popOnAction: false,
          onPressed: (_) {
            bool valid = true;
            if (this.widget.inputCheck != null) {
              _formKey.currentState!.validate();
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
