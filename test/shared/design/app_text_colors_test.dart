import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/shared/design/app_text_colors.dart';

void main() {
  group('AppTextColors.standard', () {
    test('matches the ratified dark defaults (token-delta §2.1 / §2.3)', () {
      expect(AppTextColors.standard.textPrimary.toARGB32(), 0xEBFFFFFF);
      expect(AppTextColors.standard.textSecondary.toARGB32(), 0x8CFFFFFF);
      expect(AppTextColors.standard.textTertiary.toARGB32(), 0x7AFFFFFF);
      expect(AppTextColors.standard.textOrnament.toARGB32(), 0x4DFFFFFF);
      expect(AppTextColors.standard.accentText.toARGB32(), 0xFFFF5A66);
      expect(AppTextColors.standard.highlightText.toARGB32(), 0xFF409CFF);
    });
  });

  group('AppTextColors.derive', () {
    test('reproduces the ratified …Text values from the default brand colors',
        () {
      final AppTextColors derived = AppTextColors.derive(
        accent: const Color(0xFFFF4654),
        highlight: const Color(0xFF0A84FF),
      );

      // Ratified accentText #FF5A66
      expect(derived.accentText.r * 255, closeTo(255, 0.5));
      expect(derived.accentText.g * 255, closeTo(90, 1.0));
      expect(derived.accentText.b * 255, closeTo(102, 1.0));

      // Ratified highlightText #409CFF (G lands within rounding - no single
      // sRGB mix hits all three channels exactly)
      expect(derived.highlightText.r * 255, closeTo(64, 1.0));
      expect(derived.highlightText.g * 255, closeTo(156, 4.0));
      expect(derived.highlightText.b * 255, closeTo(255, 0.5));
    });

    test('dark derivation keeps the standard emphasis levels', () {
      final AppTextColors derived = AppTextColors.derive(
        accent: Colors.purple,
        highlight: Colors.teal,
      );
      expect(derived.textPrimary, AppTextColors.standard.textPrimary);
      expect(derived.textOrnament, AppTextColors.standard.textOrnament);
    });

    test('light derivation inverts to black-alpha levels and darkens …Text',
        () {
      const Color accent = Color(0xFFFF4654);
      final AppTextColors derived = AppTextColors.derive(
        accent: accent,
        highlight: const Color(0xFF0A84FF),
        brightness: Brightness.light,
      );

      expect(derived.textPrimary.a, closeTo(0.6, 0.001));
      expect(derived.textSecondary.a, closeTo(0.45, 0.001));
      expect(derived.textTertiary.a, closeTo(0.38, 0.001));
      expect(derived.textPrimary.r, 0.0);

      expect(derived.accentText.r, lessThan(accent.r));
      expect(derived.accentText.g, lessThan(accent.g));
      expect(derived.accentText.b, lessThan(accent.b));
    });
  });

  group('AppTextColors.light', () {
    test('exists with black-alpha emphasis levels', () {
      expect(AppTextColors.light.textPrimary.a, closeTo(0.6, 0.001));
      expect(AppTextColors.light.textTertiary.a, closeTo(0.38, 0.001));
    });
  });

  test('copyWith and lerp behave like a proper ThemeExtension', () {
    const AppTextColors a = AppTextColors.standard;
    final AppTextColors b = a.copyWith(accentText: Colors.red);
    expect(b.accentText, Colors.red);
    expect(b.textPrimary, a.textPrimary);

    final AppTextColors mid = a.lerp(AppTextColors.light, 0.5);
    expect(mid.textPrimary.a,
        closeTo((a.textPrimary.a + AppTextColors.light.textPrimary.a) / 2, 0.01));
  });
}
