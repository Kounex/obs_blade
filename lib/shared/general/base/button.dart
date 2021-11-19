import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BaseButton extends StatelessWidget {
  final String? text;
  final Widget? child;

  final Widget? icon;

  final bool secondary;

  final Color? color;

  /// Used to override the [minimumSize] (will be 0 "extra" width) so the
  /// width of the button can be more granulary set with the [padding] property
  final bool shrinkWidth;

  final VoidCallback? onPressed;
  final bool isDestructive;

  final EdgeInsetsGeometry? padding;

  const BaseButton({
    Key? key,
    this.text,
    this.child,
    this.icon,
    this.secondary = false,
    this.color,
    this.shrinkWidth = false,
    this.onPressed,
    this.isDestructive = false,
    this.padding,
  })  : assert(child != null || text != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    ButtonStyle style = ElevatedButton.styleFrom(
      padding: this.padding,
      minimumSize: this.shrinkWidth ? const Size(0, 36) : null,
      primary: this.isDestructive
          ? CupertinoColors.destructiveRed
          : this.secondary
              ? Colors.transparent
              : this.color ?? Theme.of(context).colorScheme.secondary,
      side: !this.isDestructive && this.secondary
          ? BorderSide(
              color: this.color ?? Theme.of(context).colorScheme.secondary,
              width: 1.0,
            )
          : null,
    );

    return this.icon != null
        ? ElevatedButton.icon(
            style: style,
            icon: this.icon!,
            label: this.child ??
                FittedBox(
                  child: Text(this.text!),
                ),
            onPressed: onPressed,
          )
        : ElevatedButton(
            style: style,
            child: this.child ??
                FittedBox(
                  child: Text(this.text!),
                ),
            onPressed: this.onPressed,
          );
  }
}
