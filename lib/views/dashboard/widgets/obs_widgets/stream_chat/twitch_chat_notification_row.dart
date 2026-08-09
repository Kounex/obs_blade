import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_notification.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_notice_chrome.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_appearance.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart';

/// Body copy under the notice author — strips a leading chatter name from
/// Twitch's `system_message` and capitalizes the first letter (Twitch UI:
/// name on one line, "Subscribed for…" on the next).
@visibleForTesting
String chatNoticeBodyText({
  required String systemMessage,
  required String chatterUserName,
}) {
  var body = systemMessage;
  if (body.startsWith(chatterUserName)) {
    body = body.substring(chatterUserName.length);
  }
  body = body.trim();
  if (body.isEmpty) return body;
  return '${body[0].toUpperCase()}${body.substring(1)}';
}

/// Fixed banner label for notice types that put the chatter on the
/// attached message line (Twitch: speaker + "Announcement").
@visibleForTesting
String? chatNoticeBannerLabel(String noticeType) {
  final type = noticeType.startsWith('shared_chat_')
      ? noticeType.substring('shared_chat_'.length)
      : noticeType;
  return switch (type) {
    'announcement' => 'Announcement',
    _ => null,
  };
}

/// One `channel.chat.notification` banner — icon, system copy, optional
/// attached chat line, left accent bar (Twitch-style).
class TwitchChatNotificationRow extends StatelessWidget {
  final ChatNotificationEvent event;
  final Box settingsBox;

  /// When the next timeline item is a chat message from the same
  /// chatter, the accent continues onto that row (caller sets both).
  final bool accentContinues;

  /// When false, a separate [ChatMessageEvent] with the same [messageId]
  /// already carries the body — don't duplicate it under the banner.
  final bool showAttachedMessage;

  /// Chatter hex lookup for @mentions inside an attached message.
  final String? Function(String userId)? mentionHexFor;

  /// Opens the user card for this notice's chatter.
  final VoidCallback? onAuthorTap;

  /// Opens the user card for an `@mention` in the attached message.
  final ValueChanged<String>? onMentionTap;

  const TwitchChatNotificationRow({
    super.key,
    required this.event,
    required this.settingsBox,
    this.accentContinues = false,
    this.showAttachedMessage = true,
    this.mentionHexFor,
    this.onAuthorTap,
    this.onMentionTap,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = chatNoticeChrome(this.event.noticeType);
    final accent = chatNoticeAccentColor(chrome.color);
    final icon = chatNoticeIconData(chrome.icon);
    final textSize = NativeChatAppearance.textSize(this.settingsBox);
    final spacing = NativeChatAppearance.messageSpacing(this.settingsBox);
    final authorColor = this._parseColor(this.event.color) ?? accent;
    final bannerLabel = chatNoticeBannerLabel(this.event.noticeType);
    final body = bannerLabel != null
        ? ''
        : chatNoticeBodyText(
            systemMessage: this.event.systemMessage,
            chatterUserName: this.event.chatterUserName,
          );

    final attached = this.event.message;
    final showAttached = this.showAttachedMessage &&
        attached != null &&
        attached.text.trim().isNotEmpty;

    final titleStyle = TextStyle(
      color: bannerLabel != null ? accent : authorColor,
      fontWeight: FontWeight.w700,
      fontSize: textSize,
    );
    final Widget title = bannerLabel != null
        ? Text(bannerLabel, style: titleStyle)
        : this.onAuthorTap == null
            ? Text(this.event.chatterUserName, style: titleStyle)
            : GestureDetector(
                onTap: this.onAuthorTap,
                behavior: HitTestBehavior.translucent,
                child: Text(this.event.chatterUserName, style: titleStyle),
              );

    /// Same vertical rhythm as [TwitchChatMessageRow] (symmetric spacing,
    /// not bottom-only) so notice ↔ message gaps match message ↔ message.
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3.0,
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: this.accentContinues
                    ? const BorderRadius.vertical(top: Radius.circular(2))
                    : BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 2.0,
                          right: AppSpacing.xs,
                        ),
                        child: Icon(icon, size: 14.0, color: accent),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            title,
                            if (body.isNotEmpty)
                              Text(
                                body,
                                style: TextStyle(
                                  fontSize: textSize,
                                  height: 1.25,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (showAttached) ...[
                    const SizedBox(height: AppSpacing.xs / 2),
                    TwitchChatMessageRow(
                      event: ChatMessageEvent(
                        broadcasterUserId: this.event.broadcasterUserId,
                        chatterUserId: this.event.chatterUserId,
                        chatterUserLogin: this.event.chatterUserLogin,
                        chatterUserName: this.event.chatterUserName,
                        messageId: this.event.messageId,
                        message: attached,
                        color: this.event.color,
                        badges: this.event.badges,
                      ),
                      settingsBox: this.settingsBox,
                      mentionHexFor: this.mentionHexFor,
                      onAuthorTap: this.onAuthorTap,
                      onMentionTap: this.onMentionTap,
                      compact: true,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.length != 7) return null;
    final value = int.tryParse(hex.substring(1), radix: 16);
    if (value == null) return null;
    return Color(0xFF000000 | value);
  }
}
