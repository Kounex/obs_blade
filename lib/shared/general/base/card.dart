import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/base/constrained_box.dart';

import '../../../models/custom_theme.dart';
import '../../../types/extensions/string.dart';
import '../../../utils/styling_helper.dart';
import 'divider.dart';

const double kBaseCardMaxWidth = 640.0;
const double kBaseCardBorderRadius = 12.0;

class BaseCard extends StatelessWidget {
  final Widget child;
  final bool centerChild;

  final Widget? above;
  final Widget? below;

  final bool constrained;
  final CrossAxisAlignment constrainedAlignment;

  final Color? backgroundColor;
  final bool paintBorder;
  final Color? borderColor;

  final String? title;
  final TextStyle? titleStyle;
  final Widget? titleWidget;

  final Widget? trailingTitleWidget;

  final double topPadding;
  final double rightPadding;
  final double bottomPadding;
  final double leftPadding;

  final EdgeInsetsGeometry paddingChild;
  final EdgeInsetsGeometry titlePadding;

  final CrossAxisAlignment titleCrossAlignment;

  final double? elevation;

  const BaseCard({
    super.key,
    required this.child,
    this.above,
    this.below,
    this.centerChild = true,
    this.constrained = true,
    this.constrainedAlignment = CrossAxisAlignment.start,
    this.backgroundColor,
    this.paintBorder = false,
    this.borderColor,
    this.title,
    this.titleStyle,
    this.titleWidget,
    this.trailingTitleWidget,
    this.paddingChild = const EdgeInsets.all(18.0),
    this.topPadding = 18.0,
    this.rightPadding = 16.0,
    this.bottomPadding = 18.0,
    this.leftPadding = 16.0,
    this.titlePadding =
        const EdgeInsets.only(left: 24.0, right: 24.0, top: 12.0, bottom: 12.0),
    this.titleCrossAlignment = CrossAxisAlignment.center,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    CustomTheme? customTheme = StylingHelper.currentCustomTheme();

    Widget card = Padding(
      padding: EdgeInsets.only(
        top: this.topPadding,
        right: this.rightPadding,
        bottom: this.bottomPadding,
        left: this.leftPadding,
      ),
      child: Card(
        clipBehavior: Clip.hardEdge,
        shadowColor: this.backgroundColor != null &&
                this.backgroundColor!.value == Colors.transparent.value
            ? Colors.transparent
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kBaseCardBorderRadius),
          side: this.paintBorder
              ? BorderSide(
                  color: this.borderColor ??
                      (Theme.of(context).cardColor.computeLuminance() <= 0.2
                          ? Colors.white
                          : Colors.black),
                )
              : customTheme?.cardBorderColorHex != null
                  ? BorderSide(
                      color: customTheme!.cardBorderColorHex!
                          .hexToColor()
                          .withOpacity(0.6),
                    )
                  : BorderSide.none,
        ),
        color: this.backgroundColor ?? Theme.of(context).cardColor,
        elevation: this.elevation,
        margin: const EdgeInsets.all(0),
        child: Column(
          mainAxisAlignment: this.centerChild
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (this.titleWidget != null || this.title != null)
              Padding(
                padding: this.titlePadding,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: this.titleWidget == null
                            ? Text(
                                this.title!,
                                style: this.titleStyle ??
                                    Theme.of(context).textTheme.headlineSmall,
                              )
                            : this.titleWidget!),
                    if (this.trailingTitleWidget != null)
                      this.trailingTitleWidget!
                  ],
                ),
              ),
            if (this.titleWidget != null || this.title != null)
              const BaseDivider(),
            Padding(
              padding: this.paddingChild,
              child: this.child,
            ),
          ],
        ),
      ),
    );

    if (!this.constrained) return card;

    return Center(
      child: BaseConstrainedBox(
        maxWidth: kBaseCardMaxWidth,
        child: Column(
          crossAxisAlignment: this.constrainedAlignment,
          children: [
            this.above ?? const SizedBox(),
            card,
            this.below ?? const SizedBox(),
          ],
        ),
      ),
    );
  }
}
