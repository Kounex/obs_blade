import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StatusDot extends StatefulWidget {
  final double size;
  final Color color;
  final String text;
  final Axis direction;
  final TextStyle? style;

  StatusDot({
    Key? key,
    this.size = 12.0,
    this.color = CupertinoColors.destructiveRed,
    required this.text,
    this.direction = Axis.horizontal,
    this.style,
  }) : super(key: key);

  @override
  _StatusDotState createState() => _StatusDotState();
}

class _StatusDotState extends State<StatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    _controller = AnimationController(
        duration: Duration(milliseconds: 4000), vsync: this);

    _opacity = Tween<double>(begin: 0.5, end: 0.0).animate(CurvedAnimation(
        parent: _controller, curve: Interval(0.2, 0.5, curve: Curves.easeOut)));

    _scale = Tween<double>(begin: 1.0, end: 2.0).animate(CurvedAnimation(
        parent: _controller, curve: Interval(0.2, 0.5, curve: Curves.easeOut)));

    _controller.repeat();

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget dot = Container(
      height: this.widget.size,
      width: this.widget.size,
      decoration: BoxDecoration(
        color: this.widget.color,
        borderRadius: BorderRadius.all(Radius.circular(this.widget.size)),
      ),
    );
    List<Widget> children = [
      Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => ScaleTransition(
              scale: _scale,
              child: FadeTransition(
                opacity: _opacity,
                child: dot,
              ),
            ),
          ),
          dot,
        ],
      ),
      Padding(
        padding: EdgeInsets.only(
          top: this.widget.direction == Axis.horizontal ? 0.0 : 4.0,
          left: this.widget.direction == Axis.horizontal ? 8.0 : 0.0,
        ),
        child: Text(
          this.widget.text,
          style: this.widget.style ?? Theme.of(context).textTheme.bodyText1,
        ),
      ),
    ];
    return this.widget.direction == Axis.horizontal
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
