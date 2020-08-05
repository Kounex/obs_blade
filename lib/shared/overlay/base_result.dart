import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class BaseResult extends StatelessWidget {
  final IconData icon;
  final bool isPositive;
  final String text;

  final double iconSize;

  BaseResult(
      {this.icon, this.isPositive = true, this.text, this.iconSize = 32.0})
      : assert((icon != null && isPositive == null) ||
            (icon == null && isPositive != null));

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          this.icon != null
              ? this.icon
              : this.isPositive
                  ? CupertinoIcons.check_mark_circled
                  : CupertinoIcons.clear_circled,
          size: this.iconSize,
        ),
        if (this.text != null)
          Padding(
            padding: EdgeInsets.only(top: 14.0),
            child: Text(
              this.text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.caption,
            ),
          )
      ],
    );
  }
}
