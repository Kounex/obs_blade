// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_chat_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatNotificationEvent _$ChatNotificationEventFromJson(
  Map<String, dynamic> json,
) => _ChatNotificationEvent(
  broadcasterUserId: json['broadcaster_user_id'] as String,
  chatterUserId: json['chatter_user_id'] as String,
  chatterUserLogin: json['chatter_user_login'] as String,
  chatterUserName: json['chatter_user_name'] as String,
  messageId: json['message_id'] as String,
  systemMessage: json['system_message'] as String,
  noticeType: json['notice_type'] as String,
  color: json['color'] as String?,
  badges:
      (json['badges'] as List<dynamic>?)
          ?.map((e) => ChatMessageBadge.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ChatMessageBadge>[],
  message: json['message'] == null
      ? null
      : ChatMessageText.fromJson(json['message'] as Map<String, dynamic>),
  watchStreak: json['watch_streak'] == null
      ? null
      : ChatNotificationWatchStreak.fromJson(
          json['watch_streak'] as Map<String, dynamic>,
        ),
);

_ChatNotificationWatchStreak _$ChatNotificationWatchStreakFromJson(
  Map<String, dynamic> json,
) => _ChatNotificationWatchStreak(
  streakCount: (json['streak_count'] as num).toInt(),
  channelPointsAwarded: (json['channel_points_awarded'] as num?)?.toInt() ?? 0,
);
