import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StatusDot extends StatefulWidget {
  final double size;
  final double horizontalSpacing;
  final double verticalSpacing;
  final Color color;
  final String? text;
  final Axis direction;
  final TextStyle? style;

  const StatusDot({
    Key? key,
    this.size = 12.0,
    this.horizontalSpacing = 8.0,
    this.verticalSpacing = 4.0,
    this.color = CupertinoColors.destructiveRed,
    this.text,
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
        duration: const Duration(milliseconds: 4000), vsync: this);

    _opacity = Tween<double>(begin: 0.5, end: 0.0).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOut)));

    _scale = Tween<double>(begin: 1.0, end: 2.0).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOut)));

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
      height: widget.size,
      width: widget.size,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.all(Radius.circular(widget.size)),
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
      if (widget.text != null)
        Padding(
          padding: EdgeInsets.only(
            top: widget.direction == Axis.horizontal
                ? 0.0
                : widget.verticalSpacing,
            left: widget.direction == Axis.horizontal
                ? widget.horizontalSpacing
                : 0.0,
          ),
          child: Text(
            widget.text!,
            style: widget.style ?? Theme.of(context).textTheme.bodyText1,
          ),
        ),
    ];
    return widget.direction == Axis.horizontal
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
