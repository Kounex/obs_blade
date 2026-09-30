import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Numeric readouts keep tabular figures so 1s-cadence values don't jiggle
const List<FontFeature> kTabularFigures = [FontFeature.tabularFigures()];

/// "On Air" type scale mapped onto the Material [TextTheme] slots so
/// existing slot usages (`headlineSmall`, `titleMedium`, `labelLarge`,
/// `bodySmall`...) pick up the scale automatically.
///
/// Platform typeface - no bundled fonts. Scale (design-system.md):
/// display 34/w700, title1 28/w700, title2 22/w600, title3 17/w600
/// (card titles), body 15/w400, callout 13/w400 (descriptions - reads the
/// resolved [AppTextColors.textSecondary] level), caption 11/w600,
/// letterSpacing 0.8 (section headers - the resolved
/// [AppTextColors.textTertiary] level, apply `.toUpperCase()` at the use
/// site).
///
/// Body tracking follows the device font, not the (possibly forced) widget
/// platform: on iOS / macOS body text keeps SF Pro's own spacing - Material's
/// added +0.5 / +0.25 / +0.4 read airy next to the tight headings. Android
/// keeps Material's spacing, which Roboto is set for.
TextTheme buildAppTextTheme(
  TextTheme base, {
  required Color textSecondary,
  required Color textTertiary,
  TargetPlatform? platform,
}) {
  final TargetPlatform fontPlatform = platform ?? defaultTargetPlatform;
  final double? bodyLetterSpacing =
      fontPlatform == TargetPlatform.iOS || fontPlatform == TargetPlatform.macOS
      ? 0.0
      : null;

  return base.copyWith(
    displaySmall: base.displaySmall?.copyWith(
      fontSize: 34.0,
      fontWeight: FontWeight.w700,
    ),

    /// title1
    headlineMedium: base.headlineMedium?.copyWith(
      fontSize: 28.0,
      fontWeight: FontWeight.w700,
    ),

    /// title2
    titleLarge: base.titleLarge?.copyWith(
      fontSize: 22.0,
      fontWeight: FontWeight.w600,
    ),

    /// title3 (card titles)
    headlineSmall: base.headlineSmall?.copyWith(
      fontSize: 17.0,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: base.titleMedium?.copyWith(
      fontSize: 15.0,
      fontWeight: FontWeight.w500,
    ),
    titleSmall: base.titleSmall?.copyWith(
      fontSize: 13.0,
      fontWeight: FontWeight.w500,
    ),

    /// body
    bodyLarge: base.bodyLarge?.copyWith(
      letterSpacing: bodyLetterSpacing,
      fontSize: 15.0,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: base.bodyMedium?.copyWith(
      letterSpacing: bodyLetterSpacing,
      fontSize: 15.0,
      fontWeight: FontWeight.w400,
    ),

    /// callout (descriptions - secondary text level)
    bodySmall: base.bodySmall?.copyWith(
      letterSpacing: bodyLetterSpacing,
      fontSize: 13.0,
      fontWeight: FontWeight.w400,
      color: textSecondary,
    ),
    labelLarge: base.labelLarge?.copyWith(
      fontSize: 15.0,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: base.labelMedium?.copyWith(
      fontSize: 12.0,
      fontWeight: FontWeight.w500,
    ),

    /// caption (section headers - tertiary text level, uppercase applied at
    /// the use site)
    labelSmall: base.labelSmall?.copyWith(
      fontSize: 11.0,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
      color: textTertiary,
    ),
  );
}
