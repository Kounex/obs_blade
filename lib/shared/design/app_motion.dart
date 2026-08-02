import 'package:flutter/animation.dart';

/// Motion tokens for the "On Air" design system.
///
/// Every new animation must use these durations/curves. Existing ad-hoc
/// durations migrate when the surrounding code is touched.
/// See `docs/redesign/design-system.md`.
class AppMotion {
  AppMotion._();

  /// 80ms - press feedback
  static const Duration instant = Duration(milliseconds: 80);

  /// 150ms - micro interactions
  static const Duration fast = Duration(milliseconds: 150);

  /// 250ms - standard (matches the existing overlay timing contract)
  static const Duration medium = Duration(milliseconds: 250);

  /// 400ms - entrances / theme crossfades
  static const Duration slow = Duration(milliseconds: 400);

  /// 700ms - celebration moments
  static const Duration dramatic = Duration(milliseconds: 700);

  /// Delay step between staggered sibling entrances
  static const Duration staggerStep = Duration(milliseconds: 30);

  /// Maximum number of items receiving an additional stagger delay
  static const int staggerMax = 12;

  /// Default curve - decelerating settle
  static const Curve standard = Curves.easeOutCubic;

  /// Emphasized curve for signature draws/morphs
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Spring-ish overshoot - press / selection only
  static const Curve spring = Curves.easeOutBack;

  /// Exits accelerate away
  static const Curve exit = Curves.easeInCubic;
}
