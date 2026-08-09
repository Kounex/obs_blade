// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'twitch_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TwitchUser _$TwitchUserFromJson(Map<String, dynamic> json) => _TwitchUser(
  id: json['id'] as String,
  login: json['login'] as String,
  displayName: json['display_name'] as String?,
  profileImageUrl: json['profile_image_url'] as String?,
  createdAt: _createdAtFromJson(json['created_at']),
);
