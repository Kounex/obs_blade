import 'dart:async';

import 'package:flutter/material.dart';

import '../design/app_motion.dart';

class Fader extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final Duration? showDuration;

  const Fader({
    super.key,
    required this.child,
    this.duration = AppMotion.fast,
    this.delay = const Duration(milliseconds: 0),
    this.curve = AppMotion.standard,
    this.showDuration,
  });

  @override
  _FaderState createState() => _FaderState();
}

class _FaderState extends State<Fader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  Timer? _forwardTimer;
  Timer? _reverseTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: this.widget.duration,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: this.widget.curve));

    /// Timers start here (not in [build]) so rebuilds can't reschedule the
    /// animation - it plays exactly once per widget lifecycle and is
    /// properly canceled (mounted-guarded) on dispose. Reduced-motion
    /// settings snap straight to the end state
    _forwardTimer = Timer(this.widget.delay, () {
      if (this.mounted) {
        if (AppMotion.reduce(this.context)) {
          _controller.value = 1.0;
        } else {
          _controller.forward();
        }
      }
    });
    if (this.widget.showDuration != null) {
      _reverseTimer = Timer(this.widget.showDuration!, () {
        if (this.mounted) {
          if (AppMotion.reduce(this.context)) {
            _controller.value = 0.0;
          } else {
            _controller.reverse();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _forwardTimer?.cancel();
    _reverseTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _animation, child: this.widget.child);
  }
}
