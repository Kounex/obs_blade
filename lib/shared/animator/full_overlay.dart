import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

class FullOverlay extends StatefulWidget {
  final Widget content;
  final Duration animationDuration;
  final Duration showDuration;

  const FullOverlay({
    Key? key,
    required this.content,
    required this.animationDuration,
    required this.showDuration,
  }) : super(key: key);

  @override
  FullOverlayState createState() => FullOverlayState();
}

class FullOverlayState extends State<FullOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _blur;
  late Animation<double> _opacity;

  late Timer _closeTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: this.widget.animationDuration);
    _blur = Tween<double>(begin: 0.0, end: 9.0)
        .animate(CurvedAnimation(curve: Curves.easeIn, parent: _controller));
    _opacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(curve: Curves.easeIn, parent: _controller));

    _controller.forward();
    _closeTimer = Timer(this.widget.showDuration, () => this.closeOverlay());
  }

  Future<void> closeOverlay() async {
    _closeTimer.cancel();
    if (this.mounted) {
      await _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox.expand(
          child: AnimatedBuilder(
            animation: _controller,
            child: const AbsorbPointer(),
            builder: (context, child) => FadeTransition(
              opacity: _opacity,
              child: Container(
                color: Colors.black26,
                child: child,
              ),
            ),
          ),
        ),
        Positioned(
          top: (MediaQuery.of(context).size.height / 2) - 75.0,
          left: (MediaQuery.of(context).size.width / 2) - 75.0,
          child: Material(
            type: MaterialType.transparency,
            child: AnimatedBuilder(
                animation: _controller,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: this.widget.content,
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
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black87
                              : Colors.white70,
                          borderRadius: const BorderRadius.all(
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
