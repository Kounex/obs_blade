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
  Widget build(BuildContext context) {
    return switch (_type) {
      InputType.Int => BaseAdaptiveTextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          onChanged: this.widget.onUpdate,
        ),
      InputType.Double => BaseAdaptiveTextField(
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: this.widget.onUpdate,
        ),
      InputType.Bool => BaseAdaptiveSwitch(
          value: this.widget.value,
          onChanged: (value) => this.widget.onUpdate?.call(value.toString()),
        ),
      InputType.String => BaseAdaptiveTextField(
          controller: _controller,
          onChanged: this.widget.onUpdate,
        ),
    };
  }
}
