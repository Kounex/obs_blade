import 'dart:ui';

/// The 8 built-in presets of OBS 32's source colors (Sources dock ->
/// right-click -> Set Color): `color-preset` value -> RGB, rendered by
/// OBS at 33% alpha
const Map<int, int> _presetColors = {
  2: 0xFF4444, // red
  3: 0xFFFF44, // yellow
  4: 0x44FF44, // green
  5: 0x44FFFF, // cyan
  6: 0x4444FF, // blue
  7: 0xFF44FF, // magenta
  8: 0x444444, // dark grey
  9: 0xFFFFFF, // white
};

/// OBS renders the built-in presets at 33% alpha (0x54)
const int _presetAlpha = 0x54;

final RegExp _hexArgb = RegExp(r'^#([0-9a-fA-F]{8})$');

/// Source color of a scene item from its private settings
/// (`GetSceneItemPrivateSettings` -> `sceneItemSettings`), mirroring how
/// OBS 32 renders it in the Sources dock:
///
/// - 'color-preset' 0 (or missing / unknown keys): no color
/// - 'color-preset' 1: custom color from 'color' in Qt `HexArgb` format
///   (`#AARRGGBB`, maps directly onto [Color]) - an empty / missing /
///   malformed value renders untinted in OBS (empty stylesheet)
/// - 'color-preset' 2-9: one of the 8 built-in presets at 33% alpha
Color? sceneItemColor(Map<String, dynamic> settings) {
  final Object? preset = settings['color-preset'];
  if (preset is! int) return null;

  if (preset == 1) {
    final Object? custom = settings['color'];
    if (custom is! String) return null;
    final match = _hexArgb.firstMatch(custom);
    if (match == null) return null;
    return Color(int.parse(match.group(1)!, radix: 16));
  }

  final int? rgb = _presetColors[preset];
  return rgb != null ? Color(_presetAlpha << 24 | rgb) : null;
}
