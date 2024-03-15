import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obs_blade/shared/animator/fader.dart';
import 'package:obs_blade/utils/styling_helper.dart';

class CustomValidationTextEditingController extends TextEditingController {
  bool submitted = false;

  late String textAtSubmission;

  /// Works like validation - return an empty String to tell it is valid and otherwise
  /// the error text which should be displayed
  final String? Function(String?)? check;

  CustomValidationTextEditingController({
    this.check,
    super.text,
  });

  bool get isValid {
    this.submit();
    return this.check?.call(this.text) == null;
  }

  void submit() {
    this.submitted = true;
    this.textAtSubmission = this.text;
    this.notifyListeners();
  }
}

class BaseAdaptiveTextField extends StatefulWidget {
  final CustomValidationTextEditingController controller;
  final String? placeholder;
  final FocusNode? focusNode;
  final TextStyle? style;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final double bottomPadding;
  final int minLines;
  final int? maxLines;
  final bool autocorrect;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final String? labelText;
  final Widget? prefix;
  final Widget? suffix;
  final Widget? suffixIcon;

  /// By default, the error text space beneath a text field is not used when
  /// there is no error meaning that if an error is present, the text will
  /// appear beneath and use up new space. Sometimes we want to use that space
  /// all the time for better overall layout alignment
  final bool errorPaddingAlways;

  final Widget? bottom;

  final TargetPlatform? platform;

  final void Function(String text)? onChanged;

  const BaseAdaptiveTextField({
    super.key,
    required this.controller,
    this.placeholder,
    this.focusNode,
    this.style,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.bottomPadding = 6.0,
    this.minLines = 1,
    this.maxLines,
    this.bottom,
    this.autocorrect = false,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.labelText,
    this.prefix,
    this.suffix,
    this.suffixIcon,
    this.errorPaddingAlways = false,
    this.platform,
    this.onChanged,
  });

  @override
  BaseAdaptiveTextFieldState createState() => BaseAdaptiveTextFieldState();
}

class BaseAdaptiveTextFieldState extends State<BaseAdaptiveTextField> {
  String? _validationText;
  late VoidCallback _textEditingListener;

  @override
  void initState() {
    _textEditingListener = () {
      if (this.widget.controller.submitted && _validationText == null) {
        String? tempVal =
            this.widget.controller.check?.call(this.widget.controller.text);
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
  void didUpdateWidget(covariant BaseAdaptiveTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (this.widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_textEditingListener);
      this.widget.controller.addListener(_textEditingListener);
      _validationText = null;
      if (this.widget.controller.submitted) {
        this.widget.controller.submit();
      }
    }
  }

  @override
  void dispose() {
    this.widget.controller.removeListener(_textEditingListener);
    super.dispose();
  }

  List<TextInputFormatter>? _textInputFormatter() {
    if (this.widget.inputFormatters != null) {
      return this.widget.inputFormatters;
    }

    if (this.widget.keyboardType == TextInputType.number) {
      return [
        FilteringTextInputFormatter.digitsOnly,
      ];
    }

    if (this.widget.keyboardType ==
        const TextInputType.numberWithOptions(decimal: true)) {
      return [
        FilteringTextInputFormatter.deny(',', replacementString: '.'),
        FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
      ];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        switch (this.widget.platform ?? Theme.of(context).platform) {
          TargetPlatform.iOS || TargetPlatform.macOS => CupertinoTextField(
              focusNode: this.widget.focusNode,
              controller: this.widget.controller,
              style: this.widget.style,
              cursorColor: Theme.of(context).textSelectionTheme.cursorColor,
              placeholder: this.widget.placeholder,
              keyboardType: this.widget.keyboardType,
              inputFormatters: _textInputFormatter(),
              minLines: this.widget.minLines,
              maxLines: this.widget.maxLines ?? this.widget.minLines,
              autocorrect: this.widget.autocorrect,
              obscureText: this.widget.obscureText,
              enabled: this.widget.enabled,
              readOnly: this.widget.readOnly,
              prefix: this.widget.prefix,
              suffix: this.widget.suffix ?? this.widget.suffixIcon,
              onChanged: this.widget.onChanged,
            ),
          _ => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: TextFormField(
                focusNode: this.widget.focusNode,
                controller: this.widget.controller,
                style: this.widget.style,
                cursorColor: Theme.of(context).textSelectionTheme.cursorColor,
                decoration: InputDecoration(
                  hintText: this.widget.placeholder,
                  labelText: this.widget.labelText,
                  prefix: this.widget.prefix,
                  suffix: this.widget.suffix,
                  suffixIcon: this.widget.suffixIcon,
                  enabledBorder: _validationText != null
                      ? UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.error),
                        )
                      : null,
                  focusedBorder: _validationText != null
                      ? UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.error),
                        )
                      : null,
                  border: _validationText != null
                      ? UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.error),
                        )
                      : null,
                ),
                keyboardType: this.widget.keyboardType,
                inputFormatters: _textInputFormatter(),
                minLines: this.widget.minLines,
                maxLines: this.widget.maxLines ?? this.widget.minLines,
                autocorrect: this.widget.autocorrect,
                obscureText: this.widget.obscureText,
                enabled: this.widget.enabled,
                readOnly: this.widget.readOnly,
                onChanged: this.widget.onChanged,
              ),
            ),
        },
        this.widget.bottom ?? const SizedBox(),
        ...[
          if (_validationText != null || this.widget.errorPaddingAlways)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(
                  top: 2.0,
                  left: StylingHelper.isApple(context) ? 4.0 : 0,
                  bottom: this.widget.bottomPadding,
                ),
                child: Fader(
                  child: Text(
                    _validationText ?? '',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: CupertinoColors.destructiveRed,
                        ),
                    // style: const TextStyle(
                    //   color: CupertinoColors.destructiveRed,
                    // ),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
