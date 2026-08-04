// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'twitch_token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TwitchToken _$TwitchTokenFromJson(Map<String, dynamic> json) => _TwitchToken(
  accessToken: json['access_token'] as String,
  refreshToken: json['refresh_token'] as String?,
  expiresIn: (json['expires_in'] as num).toInt(),
  scope:
      (json['scope'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  tokenType: json['token_type'] as String?,
);
