import 'package:flutter/material.dart';

class BaseCard extends StatelessWidget {
  final Widget child;
  final bool centerChild;

  final Color backgroundColor;
  final bool paintBorder;
  final Color borderColor;

  final String title;
  final Widget titleWidget;

  final Widget trailingTitleWidget;

  final double topPadding;
  final double rightPadding;
  final double bottomPadding;
  final double leftPadding;

  final EdgeInsetsGeometry paddingChild;
  final EdgeInsetsGeometry titlePadding;

  final CrossAxisAlignment titleCrossAlignment;

  BaseCard({
    Key key,
    @required this.child,
    this.centerChild = true,
    this.backgroundColor,
    this.paintBorder = false,
    this.borderColor,
    this.title,
    this.titleWidget,
    this.trailingTitleWidget,
    this.paddingChild = const EdgeInsets.all(24.0),
    this.topPadding = 24.0,
    this.rightPadding = 24.0,
    this.bottomPadding = 24.0,
    this.leftPadding = 24.0,
    this.titlePadding =
        const EdgeInsets.only(left: 24.0, right: 24.0, top: 12.0, bottom: 12.0),
    this.titleCrossAlignment = CrossAxisAlignment.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 500.0),
      child: Padding(
        padding: EdgeInsets.only(
          top: this.topPadding,
          right: this.rightPadding,
          bottom: this.bottomPadding,
          left: this.leftPadding,
        ),
        child: Card(
          shadowColor: this.backgroundColor != null &&
                  this.backgroundColor.value == Colors.transparent.value
              ? Colors.transparent
              : null,
          shape: this.paintBorder
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.0),
                  side: BorderSide(
                    color: this.borderColor ??
                        (Theme.of(context).cardColor.computeLuminance() <= 0.2
                            ? Colors.white
                            : Colors.black),
                  ),
                )
              : null,
          color: this.backgroundColor ?? Theme.of(context).cardColor,
          margin: EdgeInsets.all(0),
          child: Column(
            mainAxisAlignment: this.centerChild
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (this.titleWidget != null || this.title != null)
                Padding(
                  padding: this.titlePadding,
                  child: Row(
                    crossAxisAlignment:
                        this.titleCrossAlignment ?? CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: this.titleWidget == null
                              ? Text(
                                  this.title,
                                  style: Theme.of(context).textTheme.headline5,
                                )
                              : this.titleWidget),
                      if (this.trailingTitleWidget != null)
                        this.trailingTitleWidget
                    ],
                  ),
                ),
              if (this.titleWidget != null || this.title != null)
                Divider(
                  height: 0.0,
                ),
              Padding(
                padding: this.paddingChild,
                child: this.child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
