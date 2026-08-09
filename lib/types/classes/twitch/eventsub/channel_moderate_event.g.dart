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
  timeout: json['timeout'] == null
      ? null
      : ModerateTimeoutAction.fromJson(json['timeout'] as Map<String, dynamic>),
  ban: json['ban'] == null
      ? null
      : ModerateBanAction.fromJson(json['ban'] as Map<String, dynamic>),
  sharedChatDelete: json['shared_chat_delete'] == null
      ? null
      : ModerateDeleteAction.fromJson(
          json['shared_chat_delete'] as Map<String, dynamic>,
        ),
  sharedChatTimeout: json['shared_chat_timeout'] == null
      ? null
      : ModerateTimeoutAction.fromJson(
          json['shared_chat_timeout'] as Map<String, dynamic>,
        ),
  sharedChatBan: json['shared_chat_ban'] == null
      ? null
      : ModerateBanAction.fromJson(
          json['shared_chat_ban'] as Map<String, dynamic>,
        ),
);

_ModerateDeleteAction _$ModerateDeleteActionFromJson(
  Map<String, dynamic> json,
) => _ModerateDeleteAction(
  messageId: json['message_id'] as String,
  userName: json['user_name'] as String?,
);

_ModerateTimeoutAction _$ModerateTimeoutActionFromJson(
  Map<String, dynamic> json,
) => _ModerateTimeoutAction(
  userId: json['user_id'] as String,
  userName: json['user_name'] as String?,
  reason: json['reason'] as String?,
  expiresAt: DateTime.parse(json['expires_at'] as String),
);

_ModerateBanAction _$ModerateBanActionFromJson(Map<String, dynamic> json) =>
    _ModerateBanAction(
      userId: json['user_id'] as String,
      userName: json['user_name'] as String?,
      reason: json['reason'] as String?,
    );
