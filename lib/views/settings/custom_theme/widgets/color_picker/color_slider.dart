import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obs_blade/views/settings/custom_theme/widgets/color_picker/color_picker.dart';

import '../../../../../shared/general/keyboard_number_header.dart';

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
  late TextEditingController _colorVal;
  FocusNode _colorValueFocusNode = FocusNode();

  @override
  void initState() {
    String value = this.widget.value?.toString() ?? '0';
    _colorVal = TextEditingController(text: value.split('.')[0]);
    _colorValueFocusNode.addListener(() {
      if (_colorValueFocusNode.hasFocus) {
        _colorVal.selection =
            TextSelection(baseOffset: 0, extentOffset: _colorVal.text.length);
      }
    });
    super.initState();
  }

  @override
  void didUpdateWidget(covariant ColorSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    String value = this.widget.value?.toString() ?? '0';
    _colorVal = TextEditingController(text: value.split('.')[0]);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24.0,
          child: Text(
            this.widget.label ?? this.widget.colorType.label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headline6,
          ),
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
              value: double.parse(_colorVal.text),
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
                setState(() => _colorVal.text = value.toStringAsFixed(0));
              },
            ),
          ],
        )),
        SizedBox(
          width: 42.0,
          child: KeyboardNumberHeader(
            focusNode: _colorValueFocusNode,
            child: TextFormField(
              controller: _colorVal,
              focusNode: _colorValueFocusNode,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                isDense: true,
                counterText: '',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r"^([0-9]{1,2}|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"),
                    replacementString: _colorVal.text)
              ],
              autocorrect: false,
              maxLength: 3,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              onChanged: (value) {
                if (value.length == 0) {
                  _colorVal.value = TextEditingValue(
                      text: '0',
                      selection:
                          TextSelection.fromPosition(TextPosition(offset: 1)));
                } else if (value.length > 1 && value[0] == '0') {
                  _colorVal.value = TextEditingValue(
                      text: value.substring(1, 2),
                      selection:
                          TextSelection.fromPosition(TextPosition(offset: 1)));
                }
                this.widget.onChanged?.call(value);
                setState(() {});
              },
            ),
          ),
        )
      ],
    );
  }
}
