import 'package:flutter/material.dart';

import '../../../views/settings/widgets/action_block.dart/light_divider.dart';

const double kBaseCardMaxWidth = 772.0;
const double kBaseCardBorderRadius = 12.0;

class BaseCard extends StatelessWidget {
  final Widget child;
  final bool centerChild;

  final bool constrained;

  final Color? backgroundColor;
  final bool paintBorder;
  final Color? borderColor;

  final String? title;
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
    Key? key,
    required this.child,
    this.centerChild = true,
    this.constrained = true,
    this.backgroundColor,
    this.paintBorder = false,
    this.borderColor,
    this.title,
    this.titleWidget,
    this.trailingTitleWidget,
    this.paddingChild = const EdgeInsets.all(18.0),
    this.topPadding = 24.0,
    this.rightPadding = 18.0,
    this.bottomPadding = 24.0,
    this.leftPadding = 18.0,
    this.titlePadding =
        const EdgeInsets.only(left: 24.0, right: 24.0, top: 12.0, bottom: 12.0),
    this.titleCrossAlignment = CrossAxisAlignment.center,
    this.elevation = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                                style: Theme.of(context).textTheme.headline5,
                              )
                            : this.titleWidget!),
                    if (this.trailingTitleWidget != null)
                      this.trailingTitleWidget!
                  ],
                ),
              ),
            if (this.titleWidget != null || this.title != null)
              const LightDivider(),
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kBaseCardMaxWidth),
        child: card,
      ),
    );
  }
}
