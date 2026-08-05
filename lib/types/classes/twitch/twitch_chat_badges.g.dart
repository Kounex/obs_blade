// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'twitch_chat_badges.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TwitchBadgeSet _$TwitchBadgeSetFromJson(Map<String, dynamic> json) =>
    _TwitchBadgeSet(
      setId: json['set_id'] as String,
      versions:
          (json['versions'] as List<dynamic>?)
              ?.map(
                (e) => TwitchBadgeVersion.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <TwitchBadgeVersion>[],
    );

_TwitchBadgeVersion _$TwitchBadgeVersionFromJson(Map<String, dynamic> json) =>
    _TwitchBadgeVersion(
      id: json['id'] as String,
      imageUrl1x: json['image_url_1x'] as String,
      imageUrl2x: json['image_url_2x'] as String,
      imageUrl4x: json['image_url_4x'] as String,
      title: json['title'] as String?,
    );
