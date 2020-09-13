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
    _colorVal = TextEditingController(text: widget.value?.toString() ?? '0');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24.0,
          child: Text(
            widget.label ?? '',
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
            activeColor: widget.activeColor,
            onChanged: (value) {
              widget.onChanged(value.toStringAsFixed(0));
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
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 3,
              onChanged: (value) {
                int colorVal = int.parse(value);
                if (colorVal > 255) {
                  colorVal = 255;
                }
                _colorVal.text = colorVal.toString();
                widget.onChanged(value);
                setState(() {});
              },
            ),
          ),
        )
      ],
    );
  }
}
