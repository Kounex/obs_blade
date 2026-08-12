import 'eventsub/channel_chat_message.dart';

/// Helix Get Pinned Chat Message — the single active mod pin in a
/// channel (`GET /helix/chat/pins`, one pin max per channel). [message]
/// reuses the EventSub chat text/fragment shape — Helix returns the same
/// fragment layout (unknown per-fragment fields are ignored).
class TwitchPinnedMessage {
  final String messageId;
  final String broadcasterId;
  final String senderUserId;
  final String senderUserLogin;
  final String senderUserName;
  final String pinnedByUserId;
  final String pinnedByUserLogin;
  final String pinnedByUserName;
  final ChatMessageText message;

  /// When pinned. Null = pinned until the stream ends ([endsAt] is then
  /// null as well; both come from the same pin request).
  final DateTime? startsAt;

  /// Pin expiry — null means "until stream ends" (no `duration_seconds`
  /// was given on pin).
  final DateTime? endsAt;
  final DateTime? updatedAt;

  const TwitchPinnedMessage({
    required this.messageId,
    required this.broadcasterId,
    required this.senderUserId,
    required this.senderUserLogin,
    required this.senderUserName,
    required this.pinnedByUserId,
    required this.pinnedByUserLogin,
    required this.pinnedByUserName,
    required this.message,
    this.startsAt,
    this.endsAt,
    this.updatedAt,
  });

  factory TwitchPinnedMessage.fromHelixJson(Map<String, Object?> json) =>
      TwitchPinnedMessage(
        messageId: json['message_id'] as String? ?? '',
        broadcasterId: json['broadcaster_id'] as String? ?? '',
        senderUserId: json['sender_user_id'] as String? ?? '',
        senderUserLogin: json['sender_user_login'] as String? ?? '',
        senderUserName: json['sender_user_name'] as String? ?? '',
        pinnedByUserId: json['pinned_by_user_id'] as String? ?? '',
        pinnedByUserLogin: json['pinned_by_user_login'] as String? ?? '',
        pinnedByUserName: json['pinned_by_user_name'] as String? ?? '',
        message: ChatMessageText.fromJson(
          (json['message'] as Map? ?? const {})
              .cast<String, Object?>(),
        ),
        startsAt: DateTime.tryParse(json['starts_at'] as String? ?? ''),
        endsAt: DateTime.tryParse(json['ends_at'] as String? ?? ''),
        updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
      );
}
