import 'package:flutter/material.dart';

class FadeInner extends StatefulWidget {
  final Widget child;
  final Duration duration;

  FadeInner(
      {@required this.child,
      this.duration = const Duration(milliseconds: 200)});

  @override
  _FadeInnerState createState() => _FadeInnerState();
}

class _FadeInnerState extends State<FadeInner>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    _controller.forward();
    return FadeTransition(
      opacity: _animation,
      child: this.widget.child,
    );
  }
}
