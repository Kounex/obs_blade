import 'package:flutter/material.dart';

class StatusDot extends StatelessWidget {
  final double size;
  final Color color;

  StatusDot({this.size = 12.0, this.color = Colors.red});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: this.size,
      width: this.size,
      decoration: BoxDecoration(
        color: this.color,
        borderRadius: BorderRadius.all(Radius.circular(this.size)),
      ),
    );
  }
}
