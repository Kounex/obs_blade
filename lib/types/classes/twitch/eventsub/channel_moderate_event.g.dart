// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_moderate_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChannelModerateEvent _$ChannelModerateEventFromJson(
  Map<String, dynamic> json,
) => _ChannelModerateEvent(
  action: json['action'] as String,
  moderatorUserName: json['moderator_user_name'] as String,
  delete: json['delete'] == null
      ? null
      : ModerateDeleteAction.fromJson(json['delete'] as Map<String, dynamic>),
);

_ModerateDeleteAction _$ModerateDeleteActionFromJson(
  Map<String, dynamic> json,
) => _ModerateDeleteAction(
  messageId: json['message_id'] as String,
  userName: json['user_name'] as String?,
);
