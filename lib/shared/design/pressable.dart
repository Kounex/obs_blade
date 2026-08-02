import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_motion.dart';

/// Physical press feedback for tappable elements (replaces dead
/// `GestureDetector` taps): scales the child to 0.97 and dims it to 0.88
/// while pressed, then springs back on release/cancel.
///
/// Uses a [Listener] for the press animation and a tap-only
/// [GestureDetector] ([HitTestBehavior.translucent]) so it never competes
/// with scroll gestures.
class Pressable extends StatefulWidget {
  final Widget child;

  /// If null, the child is rendered without any feedback (disabled look is
  /// up to the child, same contract as `InkWell`/`GestureDetector`)
  final void Function()? onTap;

  /// Fire a light impact haptic on tap (default false)
  final bool haptic;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.haptic = false,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool get _enabled => this.widget.onTap != null;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.instant,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _press() {
    if (!_enabled) return;
    _controller.animateTo(
      1.0,
      duration: AppMotion.instant,
      curve: AppMotion.standard,
    );
  }

  void _release() {
    if (!_enabled || _controller.value == 0.0) return;
    _controller.animateBack(
      0.0,
      duration: AppMotion.fast,
      curve: AppMotion.spring,
    );
  }

  void _tap() {
    if (this.widget.haptic) {
      HapticFeedback.lightImpact();
    }
    this.widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!_enabled) {
      return this.widget.child;
    }
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _press(),
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _tap,
        child: AnimatedBuilder(
          animation: _controller,
          child: this.widget.child,
          builder: (context, child) {
            /// The spring release overshoots slightly below 0 which yields
            /// a subtle scale > 1.0 settle - clamp opacity instead
            final double value = _controller.value;
            return Opacity(
              opacity: (1.0 - 0.12 * value).clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 1.0 - 0.03 * value,
                child: child,
              ),
            );
          },
        ),
      ),
    );
  }
}
