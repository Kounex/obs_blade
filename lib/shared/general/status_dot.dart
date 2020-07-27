import 'package:flutter/material.dart';

class StatusDot extends StatelessWidget {
  final double size;
  final Color color;
  final String text;
  final Axis direction;
  final TextStyle style;

  StatusDot({
    this.size = 12.0,
    this.color = Colors.red,
    @required this.text,
    this.direction = Axis.horizontal,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      Container(
        height: this.size,
        width: this.size,
        decoration: BoxDecoration(
          color: this.color,
          borderRadius: BorderRadius.all(Radius.circular(this.size)),
        ),
      ),
      Padding(
        padding: EdgeInsets.only(
          top: this.direction == Axis.horizontal ? 0.0 : 4.0,
          left: this.direction == Axis.horizontal ? 8.0 : 0.0,
        ),
        child: Text(
          this.text,
          style: this.style ?? Theme.of(context).textTheme.bodyText1,
        ),
      ),
    ];
    return this.direction == Axis.horizontal
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: children,
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          );
  }
}
