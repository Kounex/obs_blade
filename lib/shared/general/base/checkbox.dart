import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BaseCheckbox extends StatelessWidget {
  final bool? value;
  final String? text;
  final bool smallText;

  final bool? tristate;
  final MaterialTapTargetSize? materialTapTargetSize;

  final void Function(bool?)? onChanged;

  const BaseCheckbox({
    Key? key,
    required this.value,
    this.text,
    this.smallText = false,
    this.tristate,
    this.materialTapTargetSize,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: this.value,
          tristate: this.tristate ?? false,
          materialTapTargetSize: this.materialTapTargetSize,
          onChanged: this.onChanged != null
              ? (val) {
                  HapticFeedback.lightImpact();

                  this.onChanged!(val);
                }
              : null,
        ),
        if (this.text != null)
          Transform.translate(
            offset: const Offset(-2, 0),
            child: Text(
              this.text!,
              style: this.smallText
                  ? Theme.of(context).textTheme.labelSmall
                  : null,
            ),
          ),
      ],
    );
  }
}
