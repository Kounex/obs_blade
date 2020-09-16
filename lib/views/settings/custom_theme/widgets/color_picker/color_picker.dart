import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/views/settings/custom_theme/widgets/color_picker/color_bubble.dart';
import '../../../../../utils/validation_helper.dart';
import 'color_slider.dart';
import '../../../widgets/action_block.dart/light_divider.dart';
import '../../../../../types/extensions/string.dart';

class ColorPicker extends StatefulWidget {
  final String title;
  final String description;
  final String color;
  final bool useAlpha;
  final void Function(String) onSave;

  ColorPicker({
    @required this.title,
    @required this.description,
    this.color,
    this.useAlpha = false,
    this.onSave,
  });

  @override
  _ColorPickerState createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  TextEditingController _color;
  Key _colorContainerKey;

  @override
  void initState() {
    _color = TextEditingController(text: widget.color ?? '000000');
    _colorContainerKey = Key(widget.color ?? '000000');
    super.initState();
  }

  int _getColorSliderValue(int begin) =>
      int.parse(_color.text.substring(begin, begin + 2), radix: 16);

  void _onColorSlideChange(String value, int begin) {
    String hex = int.parse(value).toRadixString(16);
    _color.text = _color.text
        .replaceRange(begin, begin + 2, hex.length == 1 ? '0$hex' : hex);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 12.0, right: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headline5,
                ),
              ),
              Row(
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      // style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  CupertinoButton(
                    onPressed: () {
                      widget.onSave?.call(_color.text);
                      Navigator.of(context).pop();
                    },
                    child: Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 12.0),
          child: Text(
            widget.description,
            style: Theme.of(context).textTheme.caption,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                height: 50.0,
                child: Row(
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
                      child: TextFormField(
                        controller: _color,
                        decoration: InputDecoration(isDense: true),
                        validator: (color) =>
                            ValidationHelper.colorHexValidator(color),
                        autovalidate: true,
                        autocorrect: false,
                        maxLength: widget.useAlpha ? 8 : 6,
                        onChanged: (value) {
                          if (ValidationHelper.colorHexValidator(_color.text) ==
                              null) {
                            _colorContainerKey = Key(_color.text);
                            setState(() {});
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: ColorBubble(
                  color: _color.text.hexToColor(),
                  size: 32.0,
                ),
              ),
            ],
          ),
        ),
        LightDivider(),
        SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.only(top: 12.0, left: 24.0, right: 16.0),
                child: Column(
                  key: _colorContainerKey,
                  children: [
                    ColorSlider(
                      label: 'R',
                      value: _getColorSliderValue(widget.useAlpha ? 2 : 0),
                      activeColor: Colors.red,
                      onChanged: (colorVal) => _onColorSlideChange(
                          colorVal, widget.useAlpha ? 2 : 0),
                    ),
                    ColorSlider(
                      label: 'G',
                      value: _getColorSliderValue(widget.useAlpha ? 4 : 2),
                      activeColor: Colors.green,
                      onChanged: (colorVal) => _onColorSlideChange(
                          colorVal, widget.useAlpha ? 4 : 2),
                    ),
                    ColorSlider(
                      label: 'B',
                      value: _getColorSliderValue(widget.useAlpha ? 6 : 4),
                      activeColor: Colors.blue,
                      onChanged: (colorVal) => _onColorSlideChange(
                          colorVal, widget.useAlpha ? 6 : 4),
                    ),
                    if (widget.useAlpha)
                      ColorSlider(
                        label: 'A',
                        value: _getColorSliderValue(0),
                        activeColor: Colors.white,
                        onChanged: (colorVal) =>
                            _onColorSlideChange(colorVal, 0),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
