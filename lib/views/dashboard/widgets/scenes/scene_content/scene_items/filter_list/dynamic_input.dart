import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/base/adaptive_switch.dart';
import 'package:obs_blade/shared/general/base/adaptive_text_field.dart';

enum InputType {
  Int,
  Double,
  String,
  Bool,
}

class DynamicInput extends StatefulWidget {
  final String label;
  final dynamic value;

  final dynamic Function(dynamic updatedValue)? onUpdate;

  const DynamicInput({
    super.key,
    required this.label,
    required this.value,
    this.onUpdate,
  });

  @override
  State<DynamicInput> createState() => _DynamicInputState();
}

class _DynamicInputState extends State<DynamicInput> {
  late final InputType _type;

  late final CustomValidationTextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    if (int.tryParse(this.widget.value.toString()) != null) {
      _type = InputType.Int;
    } else if (double.tryParse(this.widget.value.toString()) != null) {
      _type = InputType.Double;
    } else if (bool.tryParse(this.widget.value.toString()) != null) {
      _type = InputType.Bool;
    } else {
      _type = InputType.String;
    }

    _controller = CustomValidationTextEditingController(
      text: this.widget.value.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant DynamicInput oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_focusNode.hasFocus) {
      _controller.text = this.widget.value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            this.widget.label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Container(
          width: 102.0,
          alignment: Alignment.centerRight,
          child: switch (_type) {
            InputType.Int => BaseAdaptiveTextField(
                focusNode: _focusNode,
                controller: _controller,
                keyboardType: TextInputType.number,
                onChanged: (value) => int.tryParse(value) != null
                    ? this.widget.onUpdate?.call(int.parse(value))
                    : null,
              ),
            InputType.Double => BaseAdaptiveTextField(
                focusNode: _focusNode,
                controller: _controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) => double.tryParse(value) != null
                    ? this.widget.onUpdate?.call(double.parse(value))
                    : null,
              ),
            InputType.Bool => BaseAdaptiveSwitch(
                value: this.widget.value,
                onChanged: (value) => this.widget.onUpdate?.call(value),
              ),
            InputType.String => BaseAdaptiveTextField(
                focusNode: _focusNode,
                controller: _controller,
                onChanged: this.widget.onUpdate,
              ),
          },
        ),
      ],
    );
  }
}
