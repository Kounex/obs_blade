import 'package:flutter/material.dart';
import 'package:obs_blade/shared/design/design.dart';

/// Hit-slop contract (token-delta §5): interactive use gets a 44x44 minimum
/// hit area - the visual glyph stays small, the transparent expansion
/// carries the floor
const double kBaseIconButtonMinHitArea = 44.0;

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
    Widget button = Container(
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
    );

    /// 44x44 hit-area floor for interactive use; decorative use (no
    /// [onTap]) keeps the tight visual box untouched
    if (this.onTap != null &&
        (this.buttonSize ?? 0) < kBaseIconButtonMinHitArea) {
      button = SizedBox(
        width: kBaseIconButtonMinHitArea,
        height: kBaseIconButtonMinHitArea,
        child: Center(child: button),
      );
    }

    return Pressable(
      onTap: this.onTap,
      child: button,
    );
  }
}
