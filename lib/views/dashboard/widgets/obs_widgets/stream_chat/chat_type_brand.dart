import 'package:flutter/material.dart';

import '../../../../../models/enums/chat_type.dart';

/// Brand accents for the chat chrome. Owncast has no brand color in the app
/// (`null`) - call sites fall back to the theme highlight color there.
extension ChatTypeBrand on ChatType {
  Color? get brandColor => switch (this) {
    ChatType.Twitch => const Color(0xFF6441a5),
    ChatType.YouTube => const Color(0xFFFF0000),
    ChatType.Owncast => null,
    ChatType.Kick => const Color(0xFF53FC18),

    /// Neutral - its rows carry each platform's own color.
    ChatType.Combined => null,
  };
}
