import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../shared/general/keyboard_number_header.dart';

class ColorSlider extends StatefulWidget {
  final String label;
  final int value;
  final Color activeColor;

  final void Function(String) onChanged;

  ColorSlider({
    this.label,
    this.value,
    this.activeColor,
    this.onChanged,
  });

  @override
  _ColorSliderState createState() => _ColorSliderState();
}

class _ColorSliderState extends State<ColorSlider> {
  TextEditingController _colorVal;
  FocusNode _colorValueFocusNode = FocusNode();

  @override
  void initState() {
    _colorVal =
        TextEditingController(text: this.widget.value?.toString() ?? '0');
    _colorValueFocusNode.addListener(() {
      if (_colorValueFocusNode.hasFocus) {
        _colorVal.selection =
            TextSelection(baseOffset: 0, extentOffset: _colorVal.text.length);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24.0,
          child: Text(
            this.widget.label ?? '',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headline6,
          ),
        ),
        Expanded(
          child: Slider(
            value: double.parse(_colorVal.text),
            min: 0.0,
            max: 255.0,
            divisions: 255,
            activeColor: this.widget.activeColor,
            onChanged: (value) {
              this.widget.onChanged(value.toStringAsFixed(0));
              setState(() => _colorVal.text = value.toStringAsFixed(0));
            },
          ),
        ),
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
              maxLengthEnforced: true,
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
                this.widget.onChanged(value);
                setState(() {});
              },
            ),
          ),
        )
      ],
    );
  }
}
