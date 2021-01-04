import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ValidationCupertinoTextfield extends StatefulWidget {
  final TextEditingController controller;
  final String placeholder;
  final FocusNode focusNode;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final bool autocorrect;
  final double bottomPadding;
  final int minLines;
  final int maxLines;

  /// Works like validation - return an empty String to tell it is valid and otherwise
  /// the error text which should be displayed
  final String Function(String) check;

  ValidationCupertinoTextfield({
    Key key,
    @required this.controller,
    this.placeholder,
    this.check,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.autocorrect = false,
    this.bottomPadding = 4.0,
    this.minLines = 1,
    this.maxLines,
  }) : super(key: key);

  @override
  ValidationCupertinoTextfieldState createState() =>
      ValidationCupertinoTextfieldState();
}

class ValidationCupertinoTextfieldState
    extends State<ValidationCupertinoTextfield> {
  String validationText = '';
  bool _textHasBeenEdited = false;

  bool get isValid => validationText == null || validationText.length == 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CupertinoTextField(
          focusNode: this.widget.focusNode,
          controller: this.widget.controller
            ..addListener(() {
              if (!_textHasBeenEdited && this.widget.controller.text.length > 0)
                _textHasBeenEdited = true;

              if (this.widget.check != null && _textHasBeenEdited)
                setState(
                  (() => validationText =
                      this.widget.check(this.widget.controller.text)),
                );
            }),
          placeholder: this.widget.placeholder,
          keyboardType: this.widget.keyboardType,
          inputFormatters: this.widget.inputFormatters ?? [],
          autocorrect: this.widget.autocorrect,
          minLines: this.widget.minLines,
          maxLines: this.widget.maxLines ?? this.widget.minLines,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(
                top: 4.0, left: 4.0, bottom: this.widget.bottomPadding),
            child: Text(
              validationText ?? '',
              style: TextStyle(
                color: CupertinoColors.destructiveRed,
              ),
            ),
          ),
        )
      ],
    );
  }
}
