import 'package:flutter/material.dart';

import '../../../models/enums/chat_type.dart';

/// Colour identities of the paywall. The paywall is the one surface that
/// spends colour freely (design-system § Paywall exception): every hue here
/// is decorative - none of them carries a status meaning.
class ProPalette {
  ProPalette._();

  /// Current platform brand hues (the chat chrome's `brandColor` keeps the
  /// older Twitch purple for existing surfaces)
  static const Color twitch = Color(0xFF9146FF);
  static const Color kick = Color(0xFF53FC18);
  static const Color youtube = Color(0xFFFF0000);

  /// Benefit identities
  static const Color moderation = Color(0xFFFF9F0A);
  static const Color chat = Color(0xFF40C8E0);
  static const Color themes = Color(0xFFFF5CAA);

  /// Lifetime plan
  static const Color gold = Color(0xFFFFC53D);

  /// Same dark-surface test [BaseButton] uses - custom themes can flip it
  static bool darkSurface(BuildContext context) =>
      Theme.of(context).cardColor.computeLuminance() <= 0.2;

  static Color brand(ChatType type) => switch (type) {
    ChatType.Twitch => twitch,
    ChatType.Kick => kick,
    ChatType.YouTube => youtube,
    _ => twitch,
  };

  /// A platform hue readable as text / glyph ink on the current surface:
  /// lifted on dark (raw Twitch purple and YouTube red sit too dark on
  /// near-black), deepened on light (raw Kick green washes out on white)
  static Color platformInk(BuildContext context, ChatType type) {
    final bool dark = darkSurface(context);
    return switch (type) {
      ChatType.Twitch =>
        dark ? const Color(0xFFB58CF0) : const Color(0xFF6441A5),
      ChatType.Kick => dark ? kick : const Color(0xFF2B8A0C),
      ChatType.YouTube =>
        dark ? const Color(0xFFFF5A52) : const Color(0xFFD40000),
      _ => ink(context, twitch),
    };
  }

  /// Any identity hue as ink - deepened on light surfaces
  static Color ink(BuildContext context, Color color) =>
      darkSurface(context) ? color : Color.lerp(color, Colors.black, 0.35)!;
}
