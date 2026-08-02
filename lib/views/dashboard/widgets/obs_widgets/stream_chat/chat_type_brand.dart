import 'package:flutter/material.dart';

import '../../../../../models/enums/chat_type.dart';

/// Brand accents for the chat chrome. Owncast has no brand color in the app
/// (`null`) - call sites fall back to the theme highlight color there.
extension ChatTypeBrand on ChatType {
  Color? get brandColor => switch (this) {
        ChatType.Twitch => const Color(0xFF6441a5),
        ChatType.YouTube => Colors.red,
        ChatType.Owncast => null,
      };
}
