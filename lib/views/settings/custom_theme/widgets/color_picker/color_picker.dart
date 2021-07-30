import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../shared/general/themed/themed_cupertino_button.dart';
import '../../../../../types/extensions/string.dart';
import '../../../../../utils/validation_helper.dart';
import '../../../widgets/action_block.dart/light_divider.dart';
import 'color_bubble.dart';
import 'color_slider.dart';

enum PickerType {
  RGB,
  HSL,
}

extension PickerTypeFunctions on PickerType {
  String get name => {
        PickerType.RGB: 'RGB',
        PickerType.HSL: 'HSL',
      }[this]!;
}

class ColorPicker extends StatefulWidget {
  final String title;
  final String description;
  final String? color;
  final bool useAlpha;
  final void Function(String)? onSave;

  ColorPicker({
    required this.title,
    required this.description,
    this.color,
    this.useAlpha = false,
    this.onSave,
  });

  @override
  _ColorPickerState createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late TextEditingController _color;
  FocusNode _colorFocusNode = FocusNode();
  late Key _colorContainerKey;

  PickerType _pickerType = PickerType.RGB;

  late double _hue;
  late double _saturation;
  late double _lightness;

  @override
  void initState() {
    _color = TextEditingController(text: this.widget.color ?? '000000');
    _colorContainerKey = Key(_color.text);

    _setHSLColor();

    _colorFocusNode.addListener(() {
      if (_colorFocusNode.hasFocus) {
        _color.selection =
            TextSelection(baseOffset: 0, extentOffset: _color.text.length);
      }
    });
    super.initState();
  }

  void _setHSLColor() {
    HSLColor hslColor =
        HSLColor.fromColor(Color(int.parse(_color.text, radix: 16)));

    _hue = hslColor.hue;
    _saturation = (hslColor.saturation * 100).roundToDouble();
    _lightness = (hslColor.lightness * 100).roundToDouble();
  }

  double _getColorSliderValue(ColorType type) {
    if (_pickerType == PickerType.RGB) {
      int offset = type == ColorType.A
          ? 0
          : (this.widget.useAlpha ? 0 : -2) + type.hexOffset;
      return int.parse(_color.text.substring(offset, offset + 2), radix: 16)
          .toDouble();
    }
    HSLColor color =
        HSLColor.fromColor(Color(int.parse(_color.text, radix: 16)));
    switch (type) {
      case ColorType.H:
        return _hue;
      case ColorType.S:
        return _saturation;
      case ColorType.L:
        return _lightness;
      case ColorType.A:
        return color.alpha;
      default:
        return 0;
    }
  }

  void _onColorSlideChange(String value, ColorType type) {
    if (_pickerType == PickerType.RGB) {
      int offset = type == ColorType.A
          ? 0
          : (this.widget.useAlpha ? 0 : -2) + type.hexOffset;
      String hex = int.parse(value).toRadixString(16);
      _color.text =
          _color.text.replaceRange(offset, offset + 2, hex.padLeft(2, '0'));
    } else {
      HSLColor color =
          HSLColor.fromAHSL(1.0, _hue, _saturation / 100, _lightness / 100);
      // HSLColor.fromColor(Color(int.parse(_color.text, radix: 16)));
      switch (type) {
        case ColorType.H:
          _hue = double.parse(value);
          color = color.withHue(_hue);
          break;
        case ColorType.S:
          _saturation = double.parse(value);
          color = color.withSaturation(_saturation / 100);
          break;
        case ColorType.L:
          _lightness = double.parse(value);
          color = color.withLightness(_lightness / 100);
          break;
        case ColorType.A:
          color = color.withAlpha(double.parse(value));
          break;
        default:
      }
      Color rgbColor = color.toColor();
      String alphaHex = rgbColor.alpha.toRadixString(16).padLeft(2, '0');
      String redHex = rgbColor.red.toRadixString(16).padLeft(2, '0');
      String greenHex = rgbColor.green.toRadixString(16).padLeft(2, '0');
      String blueHex = rgbColor.blue.toRadixString(16).padLeft(2, '0');
      _color.text =
          (this.widget.useAlpha ? alphaHex : '') + redHex + greenHex + blueHex;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 12.0, right: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  this.widget.title,
                  style: Theme.of(context).textTheme.headline5,
                ),
              ),
              Row(
                children: [
                  ThemedCupertinoButton(
                    onPressed: () => Navigator.of(context).pop(),
                    text: 'Cancel',
                  ),
                  ThemedCupertinoButton(
                    onPressed: () {
                      this.widget.onSave?.call(_color.text);
                      Navigator.of(context).pop();
                    },
                    text: 'Save',
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12.0, bottom: 12.0),
          child: Text(
            this.widget.description,
            style: Theme.of(context).textTheme.caption,
          ),
        ),
        LightDivider(),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: CupertinoSlidingSegmentedControl<PickerType>(
                    groupValue: _pickerType,
                    children: {
                      PickerType.RGB: SizedBox(
                        width: 64.0,
                        child: Text(
                          PickerType.RGB.name,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      PickerType.HSL: SizedBox(
                        width: 64.0,
                        child: Text(
                          PickerType.HSL.name,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    },
                    onValueChanged: (pickerType) {
                      _setHSLColor();
                      setState(() => _pickerType = pickerType!);
                    },
                  ),
                ),
                LightDivider(),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(right: 24.0),
                            child: Text(
                              'Hex:',
                              style: Theme.of(context).textTheme.headline6,
                            ),
                          ),
                          SizedBox(
                              width: 150.0,
                              height: 82.0,
                              child: StatefulBuilder(
                                builder: (context, setInnerState) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 24.0),
                                    child: TextFormField(
                                      controller: _color,
                                      focusNode: _colorFocusNode,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        counterText: '',
                                        suffixText:
                                            '${_color.text.length} / ${this.widget.useAlpha ? 8 : 6}',
                                      ),
                                      validator: (color) =>
                                          ValidationHelper.colorHexValidator(
                                              color),
                                      autovalidateMode: AutovalidateMode.always,
                                      autocorrect: false,
                                      maxLength: this.widget.useAlpha ? 8 : 6,
                                      maxLengthEnforcement:
                                          MaxLengthEnforcement.enforced,
                                      // inputFormatters: [
                                      //   FilteringTextInputFormatter.allow(
                                      //     r'^[a-fA-F0-9]+$',
                                      //     replacementString: _color.text,
                                      //   )
                                      // ],
                                      onChanged: (value) {
                                        if (ValidationHelper.colorHexValidator(
                                                _color.text) ==
                                            null) {
                                          _colorContainerKey = Key(_color.text);
                                          setState(() {});
                                        }
                                        setInnerState(() {});
                                      },
                                    ),
                                  );
                                },
                              )),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: ColorBubble(
                          color: _color.text.hexToColor(),
                          size: 42.0,
                        ),
                      ),
                    ],
                  ),
                ),
                LightDivider(),
                Padding(
                  padding:
                      const EdgeInsets.only(top: 12.0, left: 24.0, right: 16.0),
                  child: Column(
                    key: _colorContainerKey,
                    children: [
                      if (_pickerType == PickerType.RGB) ...[
                        ColorSlider(
                          pickerType: _pickerType,
                          colorType: ColorType.R,
                          value: _getColorSliderValue(ColorType.R),
                          activeColor: CupertinoColors.destructiveRed,
                          onChanged: (colorVal) => _onColorSlideChange(
                            colorVal,
                            ColorType.R,
                          ),
                        ),
                        ColorSlider(
                          pickerType: _pickerType,
                          colorType: ColorType.G,
                          value: _getColorSliderValue(ColorType.G),
                          activeColor: Colors.green,
                          onChanged: (colorVal) => _onColorSlideChange(
                            colorVal,
                            ColorType.G,
                          ),
                        ),
                        ColorSlider(
                          pickerType: _pickerType,
                          colorType: ColorType.B,
                          value: _getColorSliderValue(ColorType.B),
                          activeColor: Colors.blue,
                          onChanged: (colorVal) => _onColorSlideChange(
                            colorVal,
                            ColorType.B,
                          ),
                        ),
                      ],
                      if (_pickerType == PickerType.HSL) ...[
                        ColorSlider(
                          pickerType: _pickerType,
                          colorType: ColorType.H,
                          value: _getColorSliderValue(ColorType.H),
                          saturation: _saturation,
                          lightness: _lightness,
                          onChanged: (colorVal) => _onColorSlideChange(
                            colorVal,
                            ColorType.H,
                          ),
                        ),
                        ColorSlider(
                          pickerType: _pickerType,
                          colorType: ColorType.S,
                          value: _getColorSliderValue(ColorType.S),
                          hue: _hue,
                          lightness: _lightness,
                          onChanged: (colorVal) => _onColorSlideChange(
                            colorVal,
                            ColorType.S,
                          ),
                        ),
                        ColorSlider(
                          pickerType: _pickerType,
                          colorType: ColorType.L,
                          value: _getColorSliderValue(ColorType.L),
                          hue: _hue,
                          saturation: _saturation,
                          onChanged: (colorVal) => _onColorSlideChange(
                            colorVal,
                            ColorType.L,
                          ),
                        ),
                      ],
                      if (this.widget.useAlpha)
                        ColorSlider(
                          pickerType: _pickerType,
                          colorType: ColorType.A,
                          value: _getColorSliderValue(ColorType.A),
                          activeColor: Colors.white,
                          onChanged: (colorVal) =>
                              _onColorSlideChange(colorVal, ColorType.A),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 12.0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
