import 'package:flutter/material.dart';

class BaseCard extends StatelessWidget {
  final Widget child;
  final bool centerChild;

  final String title;
  final Widget titleWidget;

  final double topPadding;
  final double rightPadding;
  final double bottomPadding;
  final double leftPadding;

  final bool noPaddingChild;
  final EdgeInsetsGeometry titlePadding;

  BaseCard({
    Key key,
    @required this.child,
    this.centerChild = true,
    this.title,
    this.titleWidget,
    this.noPaddingChild = false,
    this.topPadding = 24.0,
    this.rightPadding = 24.0,
    this.bottomPadding = 24.0,
    this.leftPadding = 24.0,
    this.titlePadding =
        const EdgeInsets.only(left: 24.0, top: 12.0, bottom: 12.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          top: this.topPadding,
          right: this.rightPadding,
          bottom: this.bottomPadding,
          left: this.leftPadding),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 500.0),
        child: Card(
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
                  child: this.titleWidget == null
                      ? Text(
                          this.title,
                          style: Theme.of(context).textTheme.headline5,
                        )
                      : this.titleWidget,
                ),
              if (this.titleWidget != null || this.title != null)
                Divider(
                  height: 0.0,
                ),
              Padding(
                padding: EdgeInsets.all(this.noPaddingChild ? 0.0 : 24.0),
                child: this.child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
