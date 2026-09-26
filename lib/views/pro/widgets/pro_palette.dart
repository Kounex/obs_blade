import 'package:flutter/material.dart';

import '../../../models/enums/chat_type.dart';

/// Colour of the paywall's icon tiles - the only place the paywall spends
/// colour (design-system § Pro paywall). Every hue is a solid tile fill
/// under a white / black glyph; copy and chrome stay neutral. Fills are
/// picked so the glyph clears 4.3:1 on its tile, independent of the
/// surface around it (light and dark themes alike).
class ProPalette {
  ProPalette._();

  /// Platform brand fills - Kick's green is too light for a white glyph,
  /// so it carries black (15:1); YouTube is a notch deeper than the raw
  /// #FF0000 so white clears 5:1
  static const Color twitch = Color(0xFF9146FF);
  static const Color kick = Color(0xFF53FC18);
  static const Color youtube = Color(0xFFE00000);

  /// Benefit tile fills (white glyph 4.3 - 5.7:1)
  static const Color moderation = Color(0xFFD9480F);
  static const Color chatTools = Color(0xFF0C8599);
  static const Color themes = Color(0xFFC2255C);

  static Color brand(ChatType type) => switch (type) {
    ChatType.Kick => kick,
    ChatType.YouTube => youtube,
    _ => twitch,
  };

  /// Glyph colour for a tile fill
  static Color onFill(Color fill) =>
      fill.computeLuminance() > 0.4 ? Colors.black : Colors.white;
}
