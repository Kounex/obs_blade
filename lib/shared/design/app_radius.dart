import 'package:flutter/painting.dart';

/// Corner radius tokens for the "On Air" design system.
///
/// [AppRadius.md] (12) is the BaseCard contract radius, dialogs use
/// [AppRadius.lg] (16).
class AppRadius {
  AppRadius._();

  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;

  /// Fully rounded ends (status pills etc.)
  static const BorderRadius pill =
      BorderRadius.all(Radius.circular(999.0));
}
