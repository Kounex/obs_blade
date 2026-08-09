import 'package:flutter/material.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_notification.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_notice_chrome.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_appearance.dart';
import 'package:hive_ce/hive.dart';

/// One `channel.chat.notification` banner — icon, system copy, optional
/// attached message, left accent bar (Twitch-style).
class TwitchChatNotificationRow extends StatelessWidget {
  final ChatNotificationEvent event;
  final Box settingsBox;

  /// When the next timeline item is a chat message from the same
  /// chatter, the accent continues onto that row (caller sets both).
  final bool accentContinues;

  const TwitchChatNotificationRow({
    super.key,
    required this.event,
    required this.settingsBox,
    this.accentContinues = false,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = chatNoticeChrome(this.event.noticeType);
    final accent = chatNoticeAccentColor(chrome.color);
    final icon = chatNoticeIconData(chrome.icon);
    final textSize = NativeChatAppearance.textSize(this.settingsBox);
    final spacing = NativeChatAppearance.messageSpacing(this.settingsBox);
    final authorColor = _parseColor(this.event.color) ?? accent;

    final attached = this.event.message?.text.trim() ?? '';

    return Padding(
      padding: EdgeInsets.only(bottom: spacing),
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
                        padding: const EdgeInsets.only(top: 2.0, right: AppSpacing.xs),
                        child: Icon(icon, size: 14.0, color: accent),
                      ),
                      Expanded(
                        child: this._systemText(textSize, authorColor),
                      ),
                    ],
                  ),
                  if (attached.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs / 2),
                    Text(
                      attached,
                      style: TextStyle(fontSize: textSize, height: 1.25),
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

  /// Prefer coloring the chatter name when [systemMessage] leads with it
  /// (Twitch's usual format); otherwise show the string as-is.
  Widget _systemText(double textSize, Color authorColor) {
    final message = this.event.systemMessage;
    final name = this.event.chatterUserName;
    if (message.startsWith(name)) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: name,
              style: TextStyle(
                color: authorColor,
                fontWeight: FontWeight.w700,
                fontSize: textSize,
              ),
            ),
            TextSpan(
              text: message.substring(name.length),
              style: TextStyle(fontSize: textSize, height: 1.25),
            ),
          ],
        ),
      );
    }
    return Text(
      message,
      style: TextStyle(fontSize: textSize, height: 1.25),
    );
  }
}
