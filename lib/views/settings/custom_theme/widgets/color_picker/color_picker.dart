import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../../utils/validation_helper.dart';
import 'color_slider.dart';
import '../../../widgets/action_block.dart/light_divider.dart';
import '../../../../../types/extensions/string.dart';

class ColorPicker extends StatefulWidget {
  final String title;
  final String color;
  final void Function(String) onSave;

  ColorPicker({@required this.title, this.color, this.onSave});

  @override
  _ColorPickerState createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  TextEditingController _color;

  @override
  void initState() {
    _color = TextEditingController(text: widget.color ?? '000000');
    super.initState();
  }

  int _getColorSliderValue(int begin, int end) =>
      int.parse(_color.text.substring(begin, end), radix: 16);

  void _onColorSlideChange(String value, int begin, int end) {
    String hex = int.parse(value).toRadixString(16);
    _color.text =
        _color.text.replaceRange(begin, end, hex.length == 1 ? '0$hex' : hex);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 12.0),
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
        LightDivider(),
        Padding(
          padding: const EdgeInsets.all(16.0),
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
                    child: TextFormField(
                      controller: _color,
                      decoration: InputDecoration(isDense: true),
                      validator: (color) =>
                          ValidationHelper.colorHexValidator(color),
                      autovalidate: true,
                      onChanged: (value) {
                        if (ValidationHelper.colorHexValidator(_color.text) ==
                            null) {
                          setState(() {});
                        }
                      },
                    ),
                  ),
                ],
              ),
              Container(
                height: 32.0,
                width: 32.0,
                decoration: BoxDecoration(
                  color: _color.text.hexToColor(),
                  border: Border.all(
                    color: Colors.black,
                    width: 1.0,
                  ),
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
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ColorSlider(
                      label: 'R',
                      value: _getColorSliderValue(0, 2),
                      activeColor: Colors.red,
                      onChanged: (colorVal) =>
                          _onColorSlideChange(colorVal, 0, 2),
                    ),
                    ColorSlider(
                      label: 'G',
                      value: _getColorSliderValue(2, 4),
                      activeColor: Colors.green,
                      onChanged: (colorVal) =>
                          _onColorSlideChange(colorVal, 2, 4),
                    ),
                    ColorSlider(
                      label: 'B',
                      value: _getColorSliderValue(4, 6),
                      activeColor: Colors.blue,
                      onChanged: (colorVal) =>
                          _onColorSlideChange(colorVal, 4, 6),
                    ),
                    // ColorSlider(
                    //   label: 'A',
                    //   value: _getColorSliderValue(0, 2),
                    //   activeColor: Colors.white,
                    //   onChanged: (colorVal) =>
                    //       _onColorSlideChange(colorVal, 0, 2),
                    // ),
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
