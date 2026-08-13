// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'automod_events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AutoModMessageHoldEvent _$AutoModMessageHoldEventFromJson(
  Map<String, dynamic> json,
) => _AutoModMessageHoldEvent(
  messageId: json['message_id'] as String,
  userId: json['user_id'] as String,
  userLogin: json['user_login'] as String,
  userName: json['user_name'] as String,
  message: AutoModMessageContent.fromJson(
    json['message'] as Map<String, dynamic>,
  ),
  reason: json['reason'] as String,
  automod: json['automod'] == null
      ? null
      : AutoModClassification.fromJson(json['automod'] as Map<String, dynamic>),
  heldAt: json['held_at'] == null
      ? null
      : DateTime.parse(json['held_at'] as String),
);

_AutoModMessageContent _$AutoModMessageContentFromJson(
  Map<String, dynamic> json,
) => _AutoModMessageContent(text: json['text'] as String);

_AutoModClassification _$AutoModClassificationFromJson(
  Map<String, dynamic> json,
) => _AutoModClassification(
  category: json['category'] as String?,
  level: (json['level'] as num?)?.toInt(),
);

_AutoModMessageUpdateEvent _$AutoModMessageUpdateEventFromJson(
  Map<String, dynamic> json,
) => _AutoModMessageUpdateEvent(
  messageId: json['message_id'] as String,
  status: json['status'] as String,
);
