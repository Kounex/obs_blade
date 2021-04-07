import 'package:flutter/material.dart';

class BaseProgressIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;

  final String? text;

  BaseProgressIndicator({
    this.text,
    this.size = 32.0,
    this.strokeWidth = 2.0,
  }) : assert(text != null && text.length > 0 || text == null);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: this.size,
          width: this.size,
          child: CircularProgressIndicator(
            color: Theme.of(context).accentColor,
            strokeWidth: this.strokeWidth,
          ),
        ),
        if (this.text != null)
          Padding(
            padding: EdgeInsets.only(top: 14.0),
            child: Text(
              this.text!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.caption,
            ),
          )
      ],
    );
  }
}
