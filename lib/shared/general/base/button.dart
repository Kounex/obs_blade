import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/utils/styling_helper.dart';

/// Filled = the screen's accent moment (accent fill, 17pt/700 white label -
/// token-delta §2.4); [secondary] = ghost (neutral white-35% border,
/// [AppTextColors.accentText] label - §2.6/§2.3)
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
    super.key,
    this.text,
    this.child,
    this.icon,
    this.secondary = false,
    this.color,
    this.shrinkWidth = false,
    this.onPressed,
    this.isDestructive = false,
    this.padding,
  }) : assert(child != null || text != null),
       super();

  @override
  Widget build(BuildContext context) {
    final AppTextColors textColors = Theme.of(
      context,
    ).extension<AppTextColors>()!;

    final bool darkSurface =
        Theme.of(context).cardColor.computeLuminance() <= 0.2;

    ButtonStyle style = ElevatedButton.styleFrom(
      padding: this.padding,
      elevation: 0,
      backgroundColor: this.isDestructive
          ? CupertinoColors.destructiveRed
          : this.secondary
          ? Colors.transparent
          : this.color ?? Theme.of(context).buttonTheme.colorScheme!.secondary,
      minimumSize: this.shrinkWidth
          ? const Size(0, 36)
          : const Size(64.0, 44.0),
      side: !this.isDestructive && this.secondary
          /// Ghost border (token-delta §2.6): white 35% - neutral, the accent
          /// is only spent through the label ([AppTextColors.accentText])
          ? BorderSide(
              color: (darkSurface ? Colors.white : Colors.black).withValues(
                alpha: 0.35,
              ),
              width: 1.0,
            )
          : null,
      foregroundColor: this.secondary
          ? textColors.accentText
          : StylingHelper.surroundingAwareAccent(
              surroundingColor: this.isDestructive
                  ? CupertinoColors.destructiveRed
                  : this.color ??
                        Theme.of(context).buttonTheme.colorScheme!.secondary,
            ),

      /// Filled-CTA label contract (token-delta §2.4): 17pt/700 qualifies as
      /// WCAG large text, so the white label passes on the accent fill.
      /// Ghost labels keep the default size (secondary affordance)
      textStyle: this.secondary
          ? null
          : const TextStyle(fontSize: 17.0, fontWeight: FontWeight.w700),
    );

    return Pressable(
      onTap: this.onPressed,
      child: this.icon != null
          ? ElevatedButton.icon(
              style: style,
              icon: this.icon!,
              label: this.child ?? FittedBox(child: Text(this.text!)),
              onPressed: onPressed,
            )
          : ElevatedButton(
              style: style,
              onPressed: this.onPressed,
              child: this.child ?? FittedBox(child: Text(this.text!)),
            ),
    );
  }
}
