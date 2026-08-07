// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_lifecycle_events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatMessageDeleteEvent _$ChatMessageDeleteEventFromJson(
  Map<String, dynamic> json,
) => _ChatMessageDeleteEvent(
  messageId: json['message_id'] as String,
  targetUserId: json['target_user_id'] as String,
  userName: json['user_name'] as String,
);

_ChatClearUserMessagesEvent _$ChatClearUserMessagesEventFromJson(
  Map<String, dynamic> json,
) =>
    _ChatClearUserMessagesEvent(targetUserId: json['target_user_id'] as String);

_ChatClearEvent _$ChatClearEventFromJson(Map<String, dynamic> json) =>
    _ChatClearEvent(broadcasterUserId: json['broadcaster_user_id'] as String);
