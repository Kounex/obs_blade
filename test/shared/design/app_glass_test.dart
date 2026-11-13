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

  group('SurfaceStyle (Settings -> Theme -> Bars & Sheets)', () {
    const Color glassBar = Color(0xBF101823); // alpha 0.75

    test('setting values: names, anything else is glass', () {
      expect(SurfaceStyle.fromSetting('clear'), SurfaceStyle.clear);
      expect(SurfaceStyle.fromSetting('solid'), SurfaceStyle.solid);
      expect(SurfaceStyle.fromSetting('glass'), SurfaceStyle.glass);
      expect(SurfaceStyle.fromSetting(null), SurfaceStyle.glass);
      expect(SurfaceStyle.fromSetting('frosted'), SurfaceStyle.glass);
      expect(SurfaceStyle.fromSetting(3), SurfaceStyle.glass);
    });

    test('glass blurs and keeps the glass alpha', () {
      final AppGlass glass = AppGlass.forBar(const Color(0xFF101823));
      expect(glass.style, SurfaceStyle.glass);
      expect(glass.blurs, isTrue);
      expect(glass.surface(glassBar), glassBar);
    });

    test('clear: no blur, alpha raised to the clear floor', () {
      final AppGlass glass = AppGlass.forBar(
        const Color(0xFF101823),
        style: SurfaceStyle.clear,
      );
      expect(glass.blurs, isFalse);
      expect(glass.surface(glassBar).a, closeTo(AppGlass.clearAlpha, 0.001));

      /// Never more see-through than the color it was given
      expect(glass.surface(const Color(0xF5101823)).a, closeTo(0.96, 0.01));
    });

    test('solid: no blur, opaque, same hue', () {
      final AppGlass glass = AppGlass.forBar(
        const Color(0xFF101823),
        style: SurfaceStyle.solid,
      );
      expect(glass.blurs, isFalse);
      final Color solid = glass.surface(glassBar);
      expect(solid.a, 1.0);
      expect(solid.r, closeTo(glassBar.r, 0.001));
    });

    test('copyWith keeps the style, lerp switches it halfway', () {
      final AppGlass a = AppGlass.forBar(const Color(0xFF101823));
      final AppGlass b = a.copyWith(style: SurfaceStyle.solid);
      expect(a.copyWith(sigma: 4.0).style, SurfaceStyle.glass);
      expect(a.lerp(b, 0.4).style, SurfaceStyle.glass);
      expect(a.lerp(b, 0.6).style, SurfaceStyle.solid);
    });
  });
}
