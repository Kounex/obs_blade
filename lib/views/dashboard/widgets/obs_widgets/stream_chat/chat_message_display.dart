import 'package:flutter/material.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';

/// Twitch Desktop paints broadcaster `@mentions` in this red (not the
/// streamer's name color).
const Color kChatBroadcasterMentionColor = Color(0xFFE91916);

/// LIVE viewer count / user-card LIVE label — clearer red than salmon,
/// still a touch softer than broadcaster-mention [kChatBroadcasterMentionColor].
const Color kChatViewerCountColor = Color(0xFFFF5252);

/// Fragments to render in the message body. When this is a threaded
/// reply, Twitch still includes a leading `@parent` mention fragment —
/// Desktop hides it because the "Replying to" header already names them.
List<ChatMessageFragment> fragmentsForChatDisplay(ChatMessageEvent event) {
  final reply = event.reply;
  final fragments = event.message.fragments;
  if (reply == null || fragments.isEmpty) return fragments;

  final out = <ChatMessageFragment>[];
  var trimLeadingSpace = false;
  for (final fragment in fragments) {
    if (fragment.type == 'mention' &&
        fragment.mention?.userId == reply.parentUserId) {
      trimLeadingSpace = true;
      continue;
    }
    if (trimLeadingSpace && fragment.type == 'text') {
      final trimmed = fragment.text.replaceFirst(RegExp(r'^\s+'), '');
      trimLeadingSpace = false;
      if (trimmed.isEmpty) continue;
      if (trimmed == fragment.text) {
        out.add(fragment);
      } else {
        out.add(fragment.copyWith(text: trimmed));
      }
      continue;
    }
    trimLeadingSpace = false;
    out.add(fragment);
  }
  return out;
}

/// Prefer broadcaster red; else parse [chatterHex] (`#RRGGBB`); else null
/// (caller falls back to white/bold).
Color? mentionColorForFragment({
  required String mentionUserId,
  required String broadcasterUserId,
  String? chatterHex,
}) {
  if (mentionUserId == broadcasterUserId) return kChatBroadcasterMentionColor;
  if (chatterHex == null || chatterHex.length != 7) return null;
  final value = int.tryParse(chatterHex.substring(1), radix: 16);
  if (value == null) return null;
  return Color(0xFF000000 | value);
}

/// Deterministic color for a shared-chat source channel's chip. Twitch
/// sends no color for the origin channel, and a single gray chip forces
/// reading the name every time once 3+ partner channels share a session —
/// a stable hue per channel lets the eye map chip → channel at a glance.
/// Keyed by [sourceKey] (broadcaster id when available — survives
/// renames), hashed into a fixed palette of chat-readable brights.
Color sourceChannelColor(String sourceKey) {
  const palette = [
    Color(0xFFFF6B6B), // coral red
    Color(0xFFFFA94D), // orange
    Color(0xFFFFD43B), // gold
    Color(0xFF51CF66), // green
    Color(0xFF3BC9DB), // teal
    Color(0xFF4DABF7), // blue
    Color(0xFFB197FC), // violet
    Color(0xFFF783AC), // pink
  ];
  var hash = 0;
  for (final unit in sourceKey.codeUnits) {
    hash = (hash * 31 + unit) & 0x7FFFFFFF;
  }
  return palette[hash % palette.length];
}
