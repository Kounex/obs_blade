// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'youtube_token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_YouTubeToken _$YouTubeTokenFromJson(Map<String, dynamic> json) =>
    _YouTubeToken(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
      expiresIn: (json['expires_in'] as num).toInt(),
      scope: json['scope'] == null
          ? const <String>[]
          : _scopesFromJson(json['scope']),
      tokenType: json['token_type'] as String?,
    );
