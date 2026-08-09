import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_notification.dart';

/// Maps [ChatNoticeColorSeed] / [ChatNoticeIconSeed] onto Flutter values.
Color chatNoticeAccentColor(ChatNoticeColorSeed seed) => switch (seed) {
      ChatNoticeColorSeed.sub => const Color(0xFFBF94FF),
      ChatNoticeColorSeed.streak => const Color(0xFFFF7F32),
      ChatNoticeColorSeed.raid => const Color(0xFF00D4FF),
      ChatNoticeColorSeed.announce => const Color(0xFF00C8B0),
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
