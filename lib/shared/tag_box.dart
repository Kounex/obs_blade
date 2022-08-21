import 'package:flutter/material.dart';
import 'package:obs_blade/utils/styling_helper.dart';

class TagBox extends StatelessWidget {
  final Color? color;
  final double borderRadius;
  final Icon? icon;
  final String? label;
  final Color? labelColor;

  final Widget? child;

  final double height;
  final double? width;

  const TagBox({
    super.key,
    this.color,
    this.borderRadius = 6.0,
    this.icon,
    this.label,
    this.labelColor,
    this.child,
    this.height = 24.0,
    this.width,
  }) : assert(icon != null || label != null || child != null);

  @override
  Widget build(BuildContext context) {
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
                Expanded(
                  child: Text(
                    this.label ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: this.labelColor ??
                          StylingHelper.surroundingAwareAccent(
                              context: context, surroundingColor: this.color),
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }
}
