import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'keyboard_number_header.dart';

class CupertinoNumberTextField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final double width;
  final int maxLength;

  final bool enabled;

  final String? suffix;

  final void Function(TextEditingController? controller)? onDone;

  const CupertinoNumberTextField({
    super.key,
    this.controller,
    this.focusNode,
    required this.width,
    this.maxLength = 5,
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: this.widget.width,
      child: KeyboardNumberHeader(
        focusNode: _focusNode,
        onDone: () => this.widget.onDone?.call(this.widget.controller),
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
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          keyboardType: TextInputType.number,
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
          onSubmitted: (_) => this.widget.onDone?.call(this.widget.controller),
        ),
      ),
    );
  }
}
