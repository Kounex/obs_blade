import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/utils/scene_item_color.dart';

/// The OBS 32 source-color matrix (Sources dock -> Set Color), verified
/// against obs-studio: 'color-preset' 0 = none, 1 = custom ('color' in Qt
/// HexArgb `#AARRGGBB`), 2-9 = the 8 built-in presets at 33% alpha
void main() {
  group('sceneItemColor', () {
    test('missing keys / preset 0: no color', () {
      expect(sceneItemColor(const {}), isNull);
      expect(sceneItemColor(const {'color-preset': 0}), isNull);
      expect(
        sceneItemColor(const {'color-preset': 0, 'color': '#55FF0000'}),
        isNull,
      );
    });

    test('presets 2-9: the OBS palette at 33% alpha', () {
      const expected = {
        2: Color(0x54FF4444), // red
        3: Color(0x54FFFF44), // yellow
        4: Color(0x5444FF44), // green
        5: Color(0x5444FFFF), // cyan
        6: Color(0x544444FF), // blue
        7: Color(0x54FF44FF), // magenta
        8: Color(0x54444444), // dark grey
        9: Color(0x54FFFFFF), // white
      };
      for (final entry in expected.entries) {
        expect(
          sceneItemColor({'color-preset': entry.key}),
          entry.value,
          reason: 'preset ${entry.key}',
        );
      }
    });

    test('custom: valid HexArgb maps directly onto Color', () {
      expect(
        sceneItemColor(const {'color-preset': 1, 'color': '#55FF0000'}),
        const Color(0x55FF0000),
      );
      expect(
        sceneItemColor(const {'color-preset': 1, 'color': '#FFFF0000'}),
        const Color(0xFFFF0000),
      );
      expect(
        sceneItemColor(const {'color-preset': 1, 'color': '#00ff00aa'}),
        const Color(0x00FF00AA),
      );
    });

    test('custom: empty / missing / malformed color renders untinted', () {
      expect(sceneItemColor(const {'color-preset': 1}), isNull);
      expect(sceneItemColor(const {'color-preset': 1, 'color': ''}), isNull);
      expect(
        sceneItemColor(const {'color-preset': 1, 'color': '#FF0000'}),
        isNull,
        reason: 'Qt HexArgb carries the alpha channel - 6 digits is not it',
      );
      expect(
        sceneItemColor(const {'color-preset': 1, 'color': 'FF000000'}),
        isNull,
        reason: 'missing #',
      );
      expect(
        sceneItemColor(const {'color-preset': 1, 'color': '#GGFF0000'}),
        isNull,
      );
    });

    test('garbage values: no color', () {
      expect(sceneItemColor(const {'color-preset': 10}), isNull);
      expect(sceneItemColor(const {'color-preset': -1}), isNull);
      expect(sceneItemColor(const {'color-preset': '2'}), isNull);
      expect(sceneItemColor(const {'color-preset': 2.0}), isNull);
      expect(sceneItemColor(const {'color-preset': null}), isNull);
      expect(
        sceneItemColor(const {'color-preset': 1, 'color': 0xFF0000}),
        isNull,
      );
    });
  });
}
