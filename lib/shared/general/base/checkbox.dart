import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BaseCheckbox extends StatelessWidget {
  final bool? value;

  final bool? tristate;
  final MaterialTapTargetSize? materialTapTargetSize;

  final void Function(bool?)? onChanged;

  const BaseCheckbox({
    Key? key,
    required this.value,
    this.tristate,
    this.materialTapTargetSize,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: this.value,
      tristate: this.tristate ?? false,
      materialTapTargetSize: this.materialTapTargetSize,
      onChanged: this.onChanged != null
          ? (val) {
              HapticFeedback.lightImpact();

              this.onChanged!(val);
            }
          : null,
    );
  }
}
