import 'package:flutter/material.dart';

import 'app_motion.dart';

/// Background-flash press feedback for full-width rows (settings rows,
/// statistics entries): a white (dark) / black (light) 4.5% wash snaps
/// in at [AppMotion.instant] while held and fades on release.
///
/// The token-delta press grammar reserves scale for elements with real
/// travel (buttons, tiles, icons - see [Pressable]); rows flash instead.
///
/// Same gesture shape as [Pressable]: a [Listener] for the press state
/// plus a tap-only [GestureDetector] ([HitTestBehavior.translucent]) so
/// it never competes with scroll gestures. The flash overlay is
/// pointer-transparent and clipped by the surrounding card.
class PressFlash extends StatefulWidget {
  final Widget child;

  /// If null, the child is rendered without any feedback (same contract
  /// as [Pressable])
  final void Function()? onTap;

  const PressFlash({super.key, required this.child, this.onTap});

  @override
  State<PressFlash> createState() => _PressFlashState();
}

class _PressFlashState extends State<PressFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.instant,
  );

  bool get _enabled => this.widget.onTap != null;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _press() {
    if (!_enabled) return;
    _controller.animateTo(
      1.0,
      duration: AppMotion.reduce(this.context)
          ? Duration.zero
          : AppMotion.instant,
      curve: AppMotion.standard,
    );
  }

  void _release() {
    if (!_enabled || _controller.value == 0.0) return;
    _controller.animateBack(
      0.0,
      duration: AppMotion.reduce(this.context) ? Duration.zero : AppMotion.fast,
      curve: AppMotion.standard,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_enabled) {
      return this.widget.child;
    }

    final Color flash = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _press(),
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: this.widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          child: this.widget.child,
          builder: (context, child) => Stack(
            children: [
              child!,
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: flash.withValues(alpha: 0.045 * _controller.value),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
