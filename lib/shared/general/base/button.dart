import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/utils/styling_helper.dart';

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
      elevation: 0,
      backgroundColor: this.isDestructive
          ? CupertinoColors.destructiveRed
          : this.secondary
              ? Colors.transparent
              : this.color ??
                  Theme.of(context).buttonTheme.colorScheme!.secondary,
      minimumSize: this.shrinkWidth ? const Size(0, 36) : null,
      side: !this.isDestructive && this.secondary
          ? BorderSide(
              color: this.color ??
                  Theme.of(context).buttonTheme.colorScheme!.secondary,
              width: 1.0,
            )
          : null,
      foregroundColor: StylingHelper.surroundingAwareAccent(
        surroundingColor: this.isDestructive
            ? CupertinoColors.destructiveRed
            : this.secondary
                ? Theme.of(context).cardColor
                : this.color ??
                    Theme.of(context).buttonTheme.colorScheme!.secondary,
      ),
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
            onPressed: this.onPressed,
            child: this.child ??
                FittedBox(
                  child: Text(this.text!),
                ),
          );
  }
}
