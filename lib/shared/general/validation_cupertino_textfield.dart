import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomValidationTextEditingController extends TextEditingController {
  bool submitted = false;

  late String textAtSubmission;

  /// Works like validation - return an empty String to tell it is valid and otherwise
  /// the error text which should be displayed
  final String? Function(String) check;

  CustomValidationTextEditingController({required this.check, String? text})
      : super(text: text);

  bool get isValid => this.check(this.text) == null;

  void submit() {
    this.submitted = true;
    this.textAtSubmission = this.text;
    this.notifyListeners();
  }
}

class ValidationCupertinoTextfield extends StatefulWidget {
  final CustomValidationTextEditingController controller;
  final String? placeholder;
  final FocusNode? focusNode;
  final TextStyle? style;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final double bottomPadding;
  final int minLines;
  final int? maxLines;

  final Widget? bottomWidget;

  const ValidationCupertinoTextfield({
    Key? key,
    required this.controller,
    this.placeholder,
    this.focusNode,
    this.style,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.bottomPadding = 6.0,
    this.minLines = 1,
    this.maxLines,
    this.bottomWidget,
  }) : super(key: key);

  @override
  ValidationCupertinoTextfieldState createState() =>
      ValidationCupertinoTextfieldState();
}

class ValidationCupertinoTextfieldState
    extends State<ValidationCupertinoTextfield> {
  String? _validationText;
  late VoidCallback _textEditingListener;

  @override
  void initState() {
    _textEditingListener = () {
      if (this.widget.controller.submitted && _validationText == null) {
        String? tempVal =
            this.widget.controller.check(this.widget.controller.text);
        if (tempVal != _validationText) {
          setState(() => _validationText = tempVal);
        }
      }
      if (this.widget.controller.submitted &&
          this.widget.controller.textAtSubmission !=
              this.widget.controller.text) {
        this.widget.controller.submitted = false;
        setState(() => _validationText = null);
      }
    };

    this.widget.controller.addListener(_textEditingListener);
    super.initState();
  }

  @override
  void dispose() {
    this.widget.controller.removeListener(_textEditingListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CupertinoTextField(
          focusNode: this.widget.focusNode,
          controller: this.widget.controller,
          style: this.widget.style,
          cursorColor: Theme.of(context).textSelectionTheme.cursorColor,
          placeholder: this.widget.placeholder,
          keyboardType: this.widget.keyboardType,
          inputFormatters: this.widget.inputFormatters ?? [],
          autocorrect: false,
          minLines: this.widget.minLines,
          maxLines: this.widget.maxLines ?? this.widget.minLines,
        ),
        this.widget.bottomWidget ?? Container(),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(
              top: 2.0,
              left: 4.0,
              bottom: this.widget.bottomPadding,
            ),
            child: AnimatedOpacity(
              opacity: _validationText != null ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                _validationText ?? '',
                style: const TextStyle(
                  color: CupertinoColors.destructiveRed,
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
