import 'dart:async';

import 'package:flutter/material.dart';

import 'app_motion.dart';

/// One-shot entrance: fades the child in while rising 12px, delayed by
/// `min(index, AppMotion.staggerMax) * AppMotion.staggerStep`.
///
/// MobX-rebuild-safe: the animation is driven by an [AnimationController]
/// started once in `initState` and never replays on rebuilds.
class StaggeredEntrance extends StatefulWidget {
  final Widget child;

  /// Position in the staggered group - clamped to [AppMotion.staggerMax]
  final int index;

  final Duration duration;
  final Curve curve;
  final double rise;

  /// Optional starting scale the child settles from (e.g. 0.985) - null
  /// keeps the rise-only behavior
  final double? scaleFrom;

  const StaggeredEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = AppMotion.slow,
    this.curve = AppMotion.standard,
    this.rise = 12.0,
    this.scaleFrom,
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curved;

  Timer? _delayTimer;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: this.widget.duration,
    );
    _curved = CurvedAnimation(parent: _controller, curve: this.widget.curve);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    /// Reduced motion: skip delay and duration, render at the final value
    if (AppMotion.reduce(context)) {
      _controller.value = 1.0;
      return;
    }

    final int clampedIndex = this.widget.index
        .clamp(0, AppMotion.staggerMax)
        .toInt();
    _delayTimer = Timer(AppMotion.staggerStep * clampedIndex, () {
      if (this.mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curved,
      child: this.widget.child,
      builder: (context, child) {
        Widget current = Transform.translate(
          offset: Offset(0.0, (1.0 - _curved.value) * this.widget.rise),
          child: child,
        );
        if (this.widget.scaleFrom != null) {
          current = Transform.scale(
            scale:
                this.widget.scaleFrom! +
                (1.0 - this.widget.scaleFrom!) * _curved.value,
            child: current,
          );
        }
        return Opacity(opacity: _curved.value, child: current);
      },
    );
  }
}
