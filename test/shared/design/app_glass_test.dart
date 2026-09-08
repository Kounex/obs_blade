import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/shared/design/app_glass.dart';

void main() {
  group('AppGlass (token-delta §3)', () {
    test('token defaults', () {
      const AppGlass glass = AppGlass(barColor: Color(0xC0101823));
      expect(glass.sigma, 10.0);
      expect(glass.saturate, 1.2);
      expect(glass.specularOpacity, AppGlass.specularOpacityCap);
      expect(AppGlass.specularOpacityCap, 0.28);
    });

    test('forBar derives barColor from the bar slot at glass alpha', () {
      const Color slot = Color(0xFF101823);
      final AppGlass glass = AppGlass.forBar(slot);
      expect(glass.barColor.a, closeTo(AppGlass.barAlpha, 0.001));
      expect(glass.barColor.r, closeTo(slot.r, 0.001));
      expect(glass.barColor.g, closeTo(slot.g, 0.001));
      expect(glass.barColor.b, closeTo(slot.b, 0.001));
    });

    test('copyWith and lerp behave like a proper ThemeExtension', () {
      final AppGlass a = AppGlass.forBar(const Color(0xFF101823));
      final AppGlass b = a.copyWith(sigma: 12.0);
      expect(b.sigma, 12.0);
      expect(b.barColor, a.barColor);

      final AppGlass mid = a.lerp(b, 0.5);
      expect(mid.sigma, closeTo(11.0, 0.001));
      expect(mid.barColor, a.barColor);
    });
  });
}
