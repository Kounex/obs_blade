import 'package:flutter/material.dart';

/// Text emphasis levels + derived `…Text` color variants for the "On Air"
/// design system (token-delta §2.1 / §2.3).
///
/// Registered as a [ThemeExtension] in `App._getCurrentTheme` (lib/app.dart),
/// so consumers can read:
///
/// ```dart
/// Theme.of(context).extension<AppTextColors>()!.textSecondary
/// ```
///
/// The emphasis levels are plain alpha steps (white for dark surfaces, black
/// for light surfaces - derive, don't invert). The `…Text` variants are the
/// accent/highlight slots lerped toward white on dark surfaces / toward black
/// on light surfaces so they stay readable as *text* (the raw slots are
/// fill/selection colors).
@immutable
class AppTextColors extends ThemeExtension<AppTextColors> {
  /// Titles, row labels, values, tile labels
  final Color textPrimary;

  /// Body copy, subtitles, addresses, stat keys, settings values
  final Color textSecondary;

  /// Section labels, footnotes, axis labels, version
  final Color textTertiary;

  /// Pure decoration only - never the sole carrier of meaning
  final Color textOrnament;

  /// Accent as text (selected labels on cards, ghost-CTA labels, badges)
  final Color accentText;

  /// Highlight as text (links, nav-back, chat usernames, close pill)
  final Color highlightText;

  const AppTextColors({
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textOrnament,
    required this.accentText,
    required this.highlightText,
  });

  /// Mix applied when deriving [accentText] from the accent slot (toward
  /// white on dark, toward black on light) - lands on the ratified #FF5A66
  /// for the default accent (#FF4654)
  static const double accentTextMix = 0.107;

  /// Mix applied when deriving [highlightText] from the highlight slot -
  /// lands on the ratified #409CFF (within rounding) for the default
  /// highlight (#0A84FF)
  static const double highlightTextMix = 0.22;

  /// App-wide defaults (the app is dark-first)
  static const AppTextColors standard = AppTextColors(
    textPrimary: Color(0xEBFFFFFF),
    textSecondary: Color(0x8CFFFFFF),
    textTertiary: Color(0x7AFFFFFF),
    textOrnament: Color(0x4DFFFFFF),
    accentText: Color(0xFFFF5A66),
    highlightText: Color(0xFF409CFF),
  );

  /// Light-surface defaults: same roles as black-alpha levels, `…Text`
  /// variants lerped toward black from the default brand colors
  static final AppTextColors light = AppTextColors.derive(
    accent: const Color(0xFFFF4654),
    highlight: const Color(0xFF0A84FF),
    brightness: Brightness.light,
  );

  /// Derives the extension from the active theme's accent/highlight slots -
  /// emphasis levels follow [brightness], the `…Text` variants lerp toward
  /// white (dark) / black (light)
  static AppTextColors derive({
    required Color accent,
    required Color highlight,
    Brightness brightness = Brightness.dark,
  }) {
    final bool dark = brightness == Brightness.dark;
    final Color toward = dark ? Colors.white : Colors.black;
    return AppTextColors(
      textPrimary: dark
          ? standard.textPrimary
          : Colors.black.withValues(alpha: 0.6),
      textSecondary: dark
          ? standard.textSecondary
          : Colors.black.withValues(alpha: 0.45),
      textTertiary: dark
          ? standard.textTertiary
          : Colors.black.withValues(alpha: 0.38),
      textOrnament: dark
          ? standard.textOrnament
          : Colors.black.withValues(alpha: 0.25),
      accentText: Color.lerp(accent, toward, accentTextMix)!,
      highlightText: Color.lerp(highlight, toward, highlightTextMix)!,
    );
  }

  @override
  AppTextColors copyWith({
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textOrnament,
    Color? accentText,
    Color? highlightText,
  }) => AppTextColors(
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textTertiary: textTertiary ?? this.textTertiary,
    textOrnament: textOrnament ?? this.textOrnament,
    accentText: accentText ?? this.accentText,
    highlightText: highlightText ?? this.highlightText,
  );

  @override
  AppTextColors lerp(ThemeExtension<AppTextColors>? other, double t) {
    if (other is! AppTextColors) {
      return this;
    }
    return AppTextColors(
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textOrnament: Color.lerp(textOrnament, other.textOrnament, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      highlightText: Color.lerp(highlightText, other.highlightText, t)!,
    );
  }
}
