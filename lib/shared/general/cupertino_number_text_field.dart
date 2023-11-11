import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'keyboard_number_header.dart';

class CupertinoNumberTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final double width;
  final int? maxLength;
  final bool negativeAllowed;
  final int? minValue;
  final int? maxValue;

  final TextInputType? keyboardType;

  final bool enabled;

  final String? suffix;

  final void Function()? onDone;

  const CupertinoNumberTextField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.width,
    this.maxLength,
    this.negativeAllowed = false,
    this.minValue,
    this.maxValue,
    this.keyboardType,
    this.enabled = true,
    this.suffix,
    this.onDone,
  });

  @override
  State<CupertinoNumberTextField> createState() =>
      _CupertinoNumberTextFieldState();
}

class _CupertinoNumberTextFieldState extends State<CupertinoNumberTextField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();

    _focusNode = this.widget.focusNode ?? FocusNode();
  }

  void _onDone() {
    int value = int.parse(this.widget.controller.text);
    if (this.widget.minValue != null && value < this.widget.minValue!) {
      this.widget.controller.text = this.widget.minValue.toString();
    }
    if (this.widget.minValue != null && value > this.widget.maxValue!) {
      this.widget.controller.text = this.widget.maxValue.toString();
    }
    this.widget.onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: this.widget.width,
      child: KeyboardNumberHeader(
        focusNode: _focusNode,
        onDone: _onDone,
        child: CupertinoTextField(
          focusNode: _focusNode,
          enabled: this.widget.enabled,
          controller: this.widget.controller,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFeatures: [
              FontFeature.tabularFigures(),
            ],
          ),
          maxLength: this.widget.maxLength,
          inputFormatters: [
            NegativeIntFormatter(
              negativeAllowed: this.widget.negativeAllowed,
            ),
          ],
          keyboardType: this.widget.keyboardType ??
              TextInputType.numberWithOptions(
                  signed: this.widget.negativeAllowed),
          suffix: this.widget.suffix != null
              ? Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[
                        Theme.of(context).brightness == Brightness.light
                            ? 300
                            : 900],
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(5.0),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(this.widget.suffix!),
                  ),
                )
              : const SizedBox(),
          onSubmitted: (_) => _onDone(),
        ),
      ),
    );
  }
}

class NegativeIntFormatter extends TextInputFormatter {
  final bool negativeAllowed;

  NegativeIntFormatter({
    this.negativeAllowed = true,
  });

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (!this.negativeAllowed && newValue.text.startsWith('-')) {
      return oldValue;
    }

    if (newValue.text.isEmpty || newValue.text == '-') {
      return newValue;
    }

    int? newValueInt = int.tryParse(newValue.text);

    if (newValueInt != null) {
      return TextEditingValue(text: newValueInt.toString());
    }
    return oldValue;
  }
}
