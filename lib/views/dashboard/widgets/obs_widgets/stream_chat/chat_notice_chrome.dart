import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_notification.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_type_brand.dart';

/// Maps [ChatNoticeColorSeed] / [ChatNoticeIconSeed] onto Flutter values.
Color chatNoticeAccentColor(ChatNoticeColorSeed seed) => switch (seed) {
      ChatNoticeColorSeed.sub => const Color(0xFFBF94FF),
      ChatNoticeColorSeed.streak => const Color(0xFFFF7F32),
      ChatNoticeColorSeed.raid => const Color(0xFF00D4FF),
      ChatNoticeColorSeed.announce => const Color(0xFF9147FF),
      ChatNoticeColorSeed.bits => const Color(0xFF9B6DFF),
      ChatNoticeColorSeed.charity => const Color(0xFFFF6B9D),
      ChatNoticeColorSeed.mod => const Color(0xFF00AD03),
      ChatNoticeColorSeed.generic => const Color(0xFFADADB8),
    };

IconData chatNoticeIconData(ChatNoticeIconSeed seed) => switch (seed) {
      ChatNoticeIconSeed.star => CupertinoIcons.star_fill,
      ChatNoticeIconSeed.flame => CupertinoIcons.flame_fill,
      ChatNoticeIconSeed.people => CupertinoIcons.person_2_fill,
      ChatNoticeIconSeed.megaphone => CupertinoIcons.speaker_2_fill,
      ChatNoticeIconSeed.diamond => Icons.diamond,
      ChatNoticeIconSeed.heart => CupertinoIcons.heart_fill,
      ChatNoticeIconSeed.shield => CupertinoIcons.shield_fill,
      ChatNoticeIconSeed.info => CupertinoIcons.info_circle_fill,
    };

/// First-message (`user_intro`) chrome — magenta side bars + tint.
const Color kChatFirstMessageAccent = Color(0xFFE056FD);
const Color kChatFirstMessageTint = Color(0x332D1A2F);

/// Twitch announcement highlight — dual vertical rails use a top→bottom
/// gradient (see live Twitch chat: purple/primary is violet→magenta).
/// [helixColor] is EventSub `announcement.color` / Helix send `color`.
({Color top, Color bottom, Color solid, Color tint}) chatAnnouncementHighlight(
  String? helixColor,
) {
  final primary = ChatType.Twitch.brandColor ?? const Color(0xFF9147FF);
  return switch (helixColor?.trim().toLowerCase()) {
    'blue' => (
        top: const Color(0xFF1F69FF),
        bottom: const Color(0xFF00C8FF),
        solid: const Color(0xFF1F69FF),
        tint: const Color(0x221F69FF),
      ),
    'green' => (
        top: const Color(0xFF00A32A),
        bottom: const Color(0xFF7DFF4A),
        solid: const Color(0xFF00A32A),
        tint: const Color(0x2200A32A),
      ),
    'orange' => (
        top: const Color(0xFFFF7A00),
        bottom: const Color(0xFFFFC44D),
        solid: const Color(0xFFFF7A00),
        tint: const Color(0x22FF7A00),
      ),
    'purple' => (
        top: const Color(0xFF9147FF),
        bottom: const Color(0xFFE056FD),
        solid: const Color(0xFF9147FF),
        tint: const Color(0x229147FF),
      ),
    // `primary` / unknown — channel accent (Twitch purple family).
    _ => (
        top: primary,
        bottom: const Color(0xFFE056FD),
        solid: primary,
        tint: primary.withValues(alpha: 0x22 / 255),
      ),
  };
}
