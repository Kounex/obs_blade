import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Glass tokens for the truly floating layers (nav bars, tab bar, sheets) of
/// the "On Air" design system (token-delta §3). Pure value type - consumed by
/// the `GlassBar` widget (glass_bar.dart), which every floating bar goes
/// through.
///
/// Registered as a [ThemeExtension] in `App._getCurrentTheme` (lib/app.dart),
/// so consumers can read:
///
/// ```dart
/// Theme.of(context).extension<AppGlass>()!.barColor
/// ```
@immutable
class AppGlass extends ThemeExtension<AppGlass> {
  /// Bar slot color (the theme's appBar/tabBar slot) at glass alpha
  final Color barColor;

  /// Backdrop blur sigma - matches the existing `StylingHelper.sigma_blurry`
  /// contract; higher doubles kernel cost for no visible gain
  final double sigma;

  /// Saturation boost, iOS-only garnish (second compose pass, skipped on
  /// Android)
  final double saturate;

  /// Peak opacity of the 1px specular top line (on the edge facing the
  /// content) - the sole glass signal on True Dark / opaque-fallback
  /// surfaces, never above [specularOpacityCap]
  final double specularOpacity;

  const AppGlass({
    required this.barColor,
    this.sigma = 10.0,
    this.saturate = 1.2,
    this.specularOpacity = specularOpacityCap,
  });

  /// Upper bound for [specularOpacity]
  static const double specularOpacityCap = 0.28;

  /// Alpha of the bar slot color (matches `StylingHelper.opacity_blurry`)
  static const double barAlpha = 0.75;

  /// Derives the extension from the theme's bar slot (appBar/tabBar color)
  factory AppGlass.forBar(Color barSlot) => AppGlass(
        barColor: barSlot.withValues(alpha: barAlpha),
      );

  @override
  AppGlass copyWith({
    Color? barColor,
    double? sigma,
    double? saturate,
    double? specularOpacity,
  }) =>
      AppGlass(
        barColor: barColor ?? this.barColor,
        sigma: sigma ?? this.sigma,
        saturate: saturate ?? this.saturate,
        specularOpacity: specularOpacity ?? this.specularOpacity,
      );

  @override
  AppGlass lerp(ThemeExtension<AppGlass>? other, double t) {
    if (other is! AppGlass) {
      return this;
    }
    return AppGlass(
      barColor: Color.lerp(barColor, other.barColor, t)!,
      sigma: lerpDouble(sigma, other.sigma, t)!,
      saturate: lerpDouble(saturate, other.saturate, t)!,
      specularOpacity:
          lerpDouble(specularOpacity, other.specularOpacity, t)!,
    );
  }
}
