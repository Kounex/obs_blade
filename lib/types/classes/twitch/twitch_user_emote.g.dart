// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'twitch_user_emote.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TwitchUserEmote _$TwitchUserEmoteFromJson(Map<String, dynamic> json) =>
    _TwitchUserEmote(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerId: json['owner_id'] as String,
      emoteType: json['emote_type'] as String? ?? '',
      emoteSetId: json['emote_set_id'] as String? ?? '',
    );
