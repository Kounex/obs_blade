import 'package:flutter/material.dart';

class BaseCard extends StatelessWidget {
  final Widget child;

  final String title;
  final Widget titleWidget;

  final EdgeInsetsGeometry padding;
  final bool noPaddingChild;

  BaseCard(
      {Key key,
      @required this.child,
      this.title,
      this.titleWidget,
      this.padding = const EdgeInsets.all(24.0),
      this.noPaddingChild = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: this.padding,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (this.titleWidget != null || this.title != null)
              Padding(
                padding:
                    const EdgeInsets.only(left: 24.0, top: 12.0, bottom: 12.0),
                child: this.titleWidget == null
                    ? Text(
                        this.title,
                        style: Theme.of(context)
                            .textTheme
                            .headline5
                            .copyWith(color: Colors.white),
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
    );
  }
}
