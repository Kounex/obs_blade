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

/// Cache key of a scene item's color (DashboardStore.sceneItemColors):
/// the item's own scene (the displayed scene for top-level items, the
/// parent group's source name for children) + its id. Length-prefixed so
/// names containing the `|` separator (OBS allows it) stay unambiguous -
/// [sceneItemColorKeyParts] parses it back
String sceneItemColorKey(String sceneName, int sceneItemId) =>
    '${sceneName.length}:$sceneName|$sceneItemId';

/// Inverse of [sceneItemColorKey] (null on a malformed key)
({String sceneName, int sceneItemId})? sceneItemColorKeyParts(String key) {
  final sep = key.indexOf(':');
  if (sep < 1) return null;
  final length = int.tryParse(key.substring(0, sep));
  if (length == null || key.length < sep + 1 + length + 1) return null;
  if (key[sep + 1 + length] != '|') return null;
  final sceneItemId = int.tryParse(key.substring(sep + 1 + length + 1));
  if (sceneItemId == null) return null;
  return (
    sceneName: key.substring(sep + 1, sep + 1 + length),
    sceneItemId: sceneItemId,
  );
}
