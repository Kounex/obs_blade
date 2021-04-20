import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ThemedCupertinoButton extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry? padding;
  final bool isDestructive;
  final double? minSize;

  final void Function()? onPressed;

  ThemedCupertinoButton({
    required this.text,
    this.padding,
    this.isDestructive = false,
    this.minSize,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minSize: this.minSize ?? kMinInteractiveDimensionCupertino,
      padding: this.padding,
      child: Text(
        this.text,
        style: TextStyle(
          color: this.onPressed != null
              ? this.isDestructive
                  ? CupertinoColors.destructiveRed
                  : Theme.of(context).cupertinoOverrideTheme!.primaryColor
              : null,
        ),
      ),
      onPressed: this.onPressed,
    );
  }
}
