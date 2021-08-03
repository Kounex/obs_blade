import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obs_blade/views/settings/custom_theme/widgets/color_picker/color_label.dart';

import '../../../../../shared/general/keyboard_number_header.dart';
import '../../../../../shared/general/validation_cupertino_textfield.dart';
import '../../../../../utils/validation_helper.dart';
import 'color_picker.dart';

enum ColorType {
  R,
  G,
  B,
  H,
  S,
  L,
  A,
}

extension ColorTypeFunction on ColorType {
  String get label => {
        ColorType.R: 'R',
        ColorType.G: 'G',
        ColorType.B: 'B',
        ColorType.H: 'H',
        ColorType.S: 'S',
        ColorType.L: 'L',
        ColorType.A: 'A',
      }[this]!;

  double get max => {
        ColorType.R: 255.0,
        ColorType.G: 255.0,
        ColorType.B: 255.0,
        ColorType.H: 360.0,
        ColorType.S: 100.0,
        ColorType.L: 100.0,
        ColorType.A: 1.0,
      }[this]!;

  int get divisions => {
        ColorType.R: 255,
        ColorType.G: 255,
        ColorType.B: 255,
        ColorType.H: 360,
        ColorType.S: 100,
        ColorType.L: 100,
        ColorType.A: 100,
      }[this]!;

  int get hexOffset => {
        ColorType.R: 2,
        ColorType.G: 4,
        ColorType.B: 6,
        ColorType.H: 0,
        ColorType.S: 0,
        ColorType.L: 0,
        ColorType.A: 0,
      }[this]!;
}

class ColorSlider extends StatefulWidget {
  final CustomValidationTextEditingController? controller;

  final String? label;
  final double? value;
  final Color? activeColor;

  final PickerType pickerType;
  final ColorType colorType;

  final double? hue;
  final double? saturation;
  final double? lightness;

  final void Function(String)? onChanged;

  ColorSlider({
    this.controller,
    this.label,
    this.value,
    this.activeColor,
    required this.pickerType,
    required this.colorType,
    this.hue,
    this.saturation,
    this.lightness,
    this.onChanged,
  });

  @override
  _ColorSliderState createState() => _ColorSliderState();
}

class _ColorSliderState extends State<ColorSlider> {
  FocusNode _colorValueFocusNode = FocusNode();

  late double _latestValidSliderValue;

  @override
  void initState() {
    _latestValidSliderValue = this.widget.value ?? 0;
    _setColorVal(this.widget.value);

    _colorValueFocusNode.addListener(() {
      if (this.widget.controller != null && _colorValueFocusNode.hasFocus) {
        this.widget.controller!.selection = TextSelection(
            baseOffset: 0, extentOffset: this.widget.controller!.text.length);
      }
    });
    super.initState();
  }

  @override
  void didUpdateWidget(covariant ColorSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != this.widget.value) {
      _latestValidSliderValue = this.widget.value ?? 0;
      _setColorVal(this.widget.value);
    }
  }

  void _setColorVal(double? colorVal) {
    String value = colorVal?.toString().split('.')[0] ?? '0';
    this.widget.controller?.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ColorLabel(
          label: this.widget.label ?? this.widget.colorType.label,
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (this.widget.pickerType == PickerType.HSL)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    height: 6.0,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.all(
                        Radius.circular(4.0),
                      ),
                      gradient: LinearGradient(
                        colors: List.generate(
                          this.widget.colorType == ColorType.H ? 360 : 100,
                          (index) => HSLColor.fromAHSL(
                            1.0,
                            this.widget.hue ?? index.toDouble(),
                            (this.widget.saturation ?? index.toDouble()) / 100,
                            (this.widget.lightness ?? index.toDouble()) / 100,
                          ).toColor(),
                        ),
                      ),
                    ),
                  ),
                ),
              Slider(
                value: _latestValidSliderValue,
                min: 0.0,
                max: this.widget.colorType.max,
                divisions: this.widget.colorType.divisions,
                activeColor: this.widget.pickerType == PickerType.HSL
                    ? null
                    : this.widget.activeColor,
                inactiveColor: this.widget.pickerType == PickerType.HSL
                    ? Colors.transparent
                    : null,
                onChanged: (value) {
                  this.widget.onChanged?.call(value.toStringAsFixed(0));
                  setState(() {
                    _latestValidSliderValue = value;
                    this.widget.controller?.text = value.toStringAsFixed(0);
                  });
                },
              ),
            ],
          ),
        ),
        this.widget.controller != null
            ? SizedBox(
                width: 44.0,
                child: KeyboardNumberHeader(
                  focusNode: _colorValueFocusNode,
                  // onDone: () => setState(() => this.widget.controller.text =
                  //     _latestValidSliderValue.toString().split('.')[0]),
                  child: TextFormField(
                    controller: this.widget.controller,
                    focusNode: _colorValueFocusNode,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      isDense: true,
                      counterText: '',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => ValidationHelper.colorTypeValidator(
                        value, this.widget.colorType),
                    autovalidateMode: AutovalidateMode.always,
                    autocorrect: false,
                    maxLength: 3,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    onChanged: (value) {
                      if (ValidationHelper.colorTypeValidator(
                              value, this.widget.colorType) ==
                          null) {
                        _latestValidSliderValue = double.parse(value);
                        this.widget.onChanged?.call(value);
                      }
                    },
                  ),
                ),
              )
            : ColorLabel(
                label: _latestValidSliderValue.toString().split('.')[0],
                width: 48.0,
              ),
      ],
    );
  }
}
