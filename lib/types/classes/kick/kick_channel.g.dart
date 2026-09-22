// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kick_channel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_KickChannelInfo _$KickChannelInfoFromJson(
  Map<String, dynamic> json,
) => _KickChannelInfo(
  id: (json['id'] as num).toInt(),
  userId: (json['user_id'] as num?)?.toInt(),
  slug: json['slug'] as String,
  username: _readUsername(json, 'username') as String?,
  chatroom: KickChatroom.fromJson(json['chatroom'] as Map<String, dynamic>),
  subscriberBadges:
      (json['subscriber_badges'] as List<dynamic>?)
          ?.map((e) => KickSubscriberBadge.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <KickSubscriberBadge>[],
  livestream: json['livestream'] == null
      ? null
      : KickLivestreamInfo.fromJson(json['livestream'] as Map<String, dynamic>),
);

_KickChatroom _$KickChatroomFromJson(Map<String, dynamic> json) =>
    _KickChatroom(
      id: (json['id'] as num).toInt(),
      slowMode: json['slow_mode'] as bool? ?? false,
      followersMode: json['followers_mode'] as bool? ?? false,
      subscribersMode: json['subscribers_mode'] as bool? ?? false,
      emotesMode: json['emotes_mode'] as bool? ?? false,
      messageInterval: (json['message_interval'] as num?)?.toInt() ?? 0,
      followingMinDuration:
          (json['following_min_duration'] as num?)?.toInt() ?? 0,
    );

_KickSubscriberBadge _$KickSubscriberBadgeFromJson(Map<String, dynamic> json) =>
    _KickSubscriberBadge(
      months: (json['months'] as num?)?.toInt() ?? 0,
      imageUrl: _readBadgeImage(json, 'badge_image') as String?,
    );

_KickLivestreamInfo _$KickLivestreamInfoFromJson(Map<String, dynamic> json) =>
    _KickLivestreamInfo(
      isLive: json['is_live'] as bool? ?? false,
      viewerCount: (json['viewer_count'] as num?)?.toInt(),
    );
