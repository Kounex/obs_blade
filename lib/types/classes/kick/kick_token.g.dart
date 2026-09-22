// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kick_token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_KickToken _$KickTokenFromJson(Map<String, dynamic> json) => _KickToken(
  accessToken: json['access_token'] as String,
  refreshToken: json['refresh_token'] as String?,
  expiresIn: (json['expires_in'] as num).toInt(),
  scope: json['scope'] == null
      ? const <String>[]
      : _scopesFromJson(json['scope']),
  tokenType: json['token_type'] as String?,
);
