import 'package:flutter/material.dart';
import 'package:obs_blade/utils/styling_helper.dart';

class TagBox extends StatelessWidget {
  final Color? color;
  final double borderRadius;
  final Icon? icon;
  final String? label;
  final TextStyle? labelStyle;
  final Color? labelColor;

  final Widget? child;

  final double height;
  final double? width;

  final bool expand;

  const TagBox({
    super.key,
    this.color,
    this.borderRadius = 6.0,
    this.icon,
    this.label,
    this.labelStyle,
    this.labelColor,
    this.child,
    this.height = 24.0,
    this.width,
    this.expand = true,
  }) : assert(icon != null || label != null || child != null);

  @override
  Widget build(BuildContext context) {
    Widget text = Text(
      this.label ?? '',
      textAlign: TextAlign.center,
      style: this.labelStyle ??
          TextStyle(
            color: this.labelColor ??
                StylingHelper.surroundingAwareAccent(
                    context: context, surroundingColor: this.color),
          ),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: this.color,
        borderRadius: BorderRadius.all(
          Radius.circular(this.borderRadius),
        ),
      ),
      child: SizedBox(
        height: this.height,
        width: this.width,
        child: this.child ??
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (this.icon != null) ...[
                  this.icon!,
                  const SizedBox(width: 6.0),
                ],
                this.expand
                    ? Expanded(
                        child: text,
                      )
                    : text,
              ],
            ),
      ),
    );
  }
}
