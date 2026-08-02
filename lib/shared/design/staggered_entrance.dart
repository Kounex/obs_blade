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

  const StaggeredEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = AppMotion.slow,
    this.curve = AppMotion.standard,
    this.rise = 12.0,
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curved;

  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: this.widget.duration,
    );
    _curved = CurvedAnimation(parent: _controller, curve: this.widget.curve);

    final int clampedIndex =
        this.widget.index.clamp(0, AppMotion.staggerMax).toInt();
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
      builder: (context, child) => Opacity(
        opacity: _curved.value,
        child: Transform.translate(
          offset: Offset(0.0, (1.0 - _curved.value) * this.widget.rise),
          child: child,
        ),
      ),
    );
  }
}
