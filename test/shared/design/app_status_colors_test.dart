import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/shared/design/app_status_colors.dart';

void main() {
  group('AppStatusColors.standard additions (token-delta §2.2)', () {
    test('program / recordingText / favorite match the ratified values', () {
      expect(AppStatusColors.standard.program.toARGB32(), 0xFFFF453A);
      expect(AppStatusColors.standard.recordingText.toARGB32(), 0xFFFF6B60);
      expect(AppStatusColors.standard.favorite.toARGB32(), 0xFFFFD60A);
    });

    test('existing tokens are untouched', () {
      expect(AppStatusColors.standard.live.toARGB32(), 0xFF30D158);
      expect(AppStatusColors.standard.recording.toARGB32(), 0xFFFF453A);
      expect(AppStatusColors.standard.warning.toARGB32(), 0xFFFFC107);
    });

    test('programTagFill is the 85% program / black mix (≈#D93B32)', () {
      final fill = AppStatusColors.standard.programTagFill;
      expect(fill.r * 255, closeTo(0xD9, 1.5));
      expect(fill.g * 255, closeTo(0x3B, 1.5));
      expect(fill.b * 255, closeTo(0x32, 1.5));
    });
  });

  test('copyWith and lerp cover the new fields', () {
    const AppStatusColors a = AppStatusColors.standard;
    final AppStatusColors b = a.copyWith(favorite: a.live);
    expect(b.favorite, a.live);
    expect(b.program, a.program);

    final AppStatusColors mid = a.lerp(b, 0.5);
    expect(
      mid.favorite.r * 255,
      closeTo((a.favorite.r + b.favorite.r) * 255 / 2, 1.0),
    );
    expect(mid.recordingText, a.recordingText);
  });
}
