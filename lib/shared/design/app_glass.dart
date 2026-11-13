import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Glass tokens for the truly floating layers (nav bars, tab bar, sheets) of
/// the "On Air" design system (token-delta §3). Pure value type - consumed by
/// the `GlassBar` widget (glass_bar.dart), which every floating bar goes
/// through.
///
/// Registered as a [ThemeExtension] in `App.buildTheme` (lib/app.dart),
/// so consumers can read:
///
/// ```dart
/// Theme.of(context).extension<AppGlass>()!.barColor
/// ```
/// How the floating surfaces (nav bars, tab bar, sheets, toasts) are
/// drawn - Settings -> Theme -> Bars & Sheets ([SettingsKeys.SurfaceStyle]).
/// [glass] is the design-system default; [clear] and [solid] drop the
/// backdrop blur (the cost on slower Android GPUs, issue #106)
enum SurfaceStyle {
  /// Backdrop blur + the glass-alpha surface color
  glass,

  /// No blur, a mostly opaque surface (the pre-4.0 Android look)
  clear,

  /// No blur, fully opaque surfaces
  solid;

  /// The stored setting (the enum name); anything unknown is [glass]
  static SurfaceStyle fromSetting(Object? value) => SurfaceStyle.values
      .firstWhere((style) => style.name == value, orElse: () => glass);
}

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
  /// content), never above [specularOpacityCap]
  final double specularOpacity;

  /// The user's surface style - [blurs] and [surface] apply it
  final SurfaceStyle style;

  const AppGlass({
    required this.barColor,
    this.sigma = 10.0,
    this.saturate = 1.2,
    this.specularOpacity = specularOpacityCap,
    this.style = SurfaceStyle.glass,
  });

  /// Whether floating surfaces blur what's behind them
  bool get blurs => this.style == SurfaceStyle.glass;

  /// Surface alpha floor for [SurfaceStyle.clear] - without a blur, content
  /// behind a glass-alpha (0.75) bar reads through too clearly
  static const double clearAlpha = 0.9;

  /// [base] - a surface color at its glass alpha - as drawn in [style]
  Color surface(Color base) => switch (this.style) {
    SurfaceStyle.glass => base,
    SurfaceStyle.clear => base.withValues(alpha: math.max(base.a, clearAlpha)),
    SurfaceStyle.solid => base.withValues(alpha: 1.0),
  };

  /// Upper bound for [specularOpacity]
  static const double specularOpacityCap = 0.28;

  /// Alpha of the bar slot color (matches `StylingHelper.opacity_blurry`)
  static const double barAlpha = 0.75;

  /// Derives the extension from the theme's bar slot (appBar/tabBar color)
  factory AppGlass.forBar(
    Color barSlot, {
    SurfaceStyle style = SurfaceStyle.glass,
  }) => AppGlass(
    barColor: barSlot.withValues(alpha: barAlpha),
    style: style,
  );

  @override
  AppGlass copyWith({
    Color? barColor,
    double? sigma,
    double? saturate,
    double? specularOpacity,
    SurfaceStyle? style,
  }) => AppGlass(
    barColor: barColor ?? this.barColor,
    sigma: sigma ?? this.sigma,
    saturate: saturate ?? this.saturate,
    specularOpacity: specularOpacity ?? this.specularOpacity,
    style: style ?? this.style,
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
      specularOpacity: lerpDouble(specularOpacity, other.specularOpacity, t)!,

      /// Discrete - the blur is on or off
      style: t < 0.5 ? style : other.style,
    );
  }
}
