import 'dart:ui';

import 'package:flutter/material.dart';

class FullOverlay extends StatefulWidget {
  final Widget content;
  final Duration animationDuration;
  final Duration showDuration;

  FullOverlay({
    @required this.content,
    @required this.animationDuration,
    @required this.showDuration,
  });

  @override
  _FullOverlayState createState() => _FullOverlayState();
}

class _FullOverlayState extends State<FullOverlay>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _blur;
  Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: widget.animationDuration);
    _blur = Tween<double>(begin: 0.0, end: 9.0)
        .animate(CurvedAnimation(curve: Curves.easeIn, parent: _controller));
    _opacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(curve: Curves.easeIn, parent: _controller));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _controller.forward();
    Future.delayed(
        widget.showDuration, () => this.mounted ? _controller.reverse() : null);
    return Stack(
      children: [
        SizedBox.expand(
          child: AbsorbPointer(),
        ),
        Positioned(
          top: (MediaQuery.of(context).size.height / 2) - 75.0,
          left: (MediaQuery.of(context).size.width / 2) - 75.0,
          child: Material(
            type: MaterialType.transparency,
            child: AnimatedBuilder(
                animation: _controller,
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: widget.content,
                ),
                builder: (context, child) {
                  return BackdropFilter(
                    filter: ImageFilter.blur(
                        sigmaX: _blur.value, sigmaY: _blur.value),
                    child: FadeTransition(
                      opacity: _opacity,
                      child: Container(
                        height: 150.0,
                        width: 150.0,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.all(
                            Radius.circular(12.0),
                          ),
                        ),
                        child: child,
                      ),
                    ),
                  );
                }),
          ),
        ),
      ],
    );
  }
}
