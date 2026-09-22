// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kick_chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_KickChatMessage _$KickChatMessageFromJson(Map<String, dynamic> json) =>
    _KickChatMessage(
      id: json['id'] as String,
      chatroomId: (json['chatroom_id'] as num?)?.toInt(),
      content: json['content'] as String? ?? '',
      type: json['type'] == null
          ? KickChatMessageType.message
          : KickChatMessageType.parse(json['type']),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      sender: json['sender'] == null
          ? null
          : KickChatSender.fromJson(json['sender'] as Map<String, dynamic>),
      metadata: KickChatMessageMetadata.parse(json['metadata']),
    );

_KickChatSender _$KickChatSenderFromJson(Map<String, dynamic> json) =>
    _KickChatSender(
      id: (json['id'] as num?)?.toInt(),
      username: json['username'] as String?,
      slug: json['slug'] as String?,
      identity: json['identity'] == null
          ? null
          : KickChatIdentity.fromJson(json['identity'] as Map<String, dynamic>),
    );

_KickChatIdentity _$KickChatIdentityFromJson(Map<String, dynamic> json) =>
    _KickChatIdentity(
      color: json['color'] as String?,
      badges:
          (json['badges'] as List<dynamic>?)
              ?.map(
                (e) => KickChatLegacyBadge.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <KickChatLegacyBadge>[],
      badgesV2:
          (json['badges_v2'] as List<dynamic>?)
              ?.map((e) => KickChatBadgeV2.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <KickChatBadgeV2>[],
    );

_KickChatBadgeV2 _$KickChatBadgeV2FromJson(Map<String, dynamic> json) =>
    _KickChatBadgeV2(
      name: json['name'] as String?,
      badgeType: json['badge_type'] as String?,
      imageUrl: json['image_url'] as String?,
      metadata: kickJsonObject(json['metadata']),
      selected: json['selected'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt(),
    );

_KickChatLegacyBadge _$KickChatLegacyBadgeFromJson(Map<String, dynamic> json) =>
    _KickChatLegacyBadge(
      type: json['type'] as String?,
      text: json['text'] as String?,
      count: (json['count'] as num?)?.toInt(),
    );
