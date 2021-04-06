import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ThemedCupertinoSwitch extends StatelessWidget {
  final Color? activeColor;
  final bool value;
  final Function(bool) onChanged;

  ThemedCupertinoSwitch({
    this.activeColor,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoSwitch(
        activeColor:
            this.activeColor ?? Theme.of(context).toggleableActiveColor,
        value: this.value,
        onChanged: this.onChanged);
  }
}
