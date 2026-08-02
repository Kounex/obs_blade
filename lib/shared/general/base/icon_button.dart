import 'package:flutter/material.dart';
import 'package:obs_blade/shared/design/design.dart';

class BaseIconButton extends StatelessWidget {
  final IconData? icon;
  final double? iconSize;
  final double? buttonSize;
  final Color? backgroundColor;
  final Color? foregroundColor;

  final void Function()? onTap;

  final Widget? child;

  const BaseIconButton({
    super.key,
    this.icon,
    this.iconSize,
    this.buttonSize,
    this.backgroundColor,
    this.foregroundColor,
    this.onTap,
    this.child,
  }) : assert(icon != null || child != null);

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: this.onTap,
      child: Container(
        height: this.buttonSize,
        width: this.buttonSize,
        padding: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: this.backgroundColor ??
              Theme.of(context).buttonTheme.colorScheme!.secondary,
        ),
        child: this.child ??
            Icon(
              this.icon,
              color: this.foregroundColor,
              size: this.iconSize,
            ),
      ),
    );
  }
}
