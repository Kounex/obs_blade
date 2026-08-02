import 'package:flutter/material.dart';

import '../../../../../shared/design/design.dart';

/// Toggle icon (eye / volume states) which crossfades between icon shapes
/// and tweens the tint at the same time - used for the mute / visibility
/// toggles inside the scene content panels.
class AnimatedToggleIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const AnimatedToggleIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: this.color),
      duration: AppMotion.fast,
      builder: (context, color, child) => AnimatedSwitcher(
        duration: AppMotion.fast,
        switchInCurve: AppMotion.standard,
        switchOutCurve: AppMotion.exit,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation,
            child: child,
          ),
        ),
        child: Icon(
          this.icon,
          key: ValueKey(this.icon),
          color: color,
          size: this.size,
        ),
      ),
    );
  }
}
