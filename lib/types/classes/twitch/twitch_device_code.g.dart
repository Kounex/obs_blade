// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'twitch_device_code.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TwitchDeviceCode _$TwitchDeviceCodeFromJson(Map<String, dynamic> json) =>
    _TwitchDeviceCode(
      deviceCode: json['device_code'] as String,
      userCode: json['user_code'] as String,
      verificationUri: json['verification_uri'] as String,
      expiresIn: (json['expires_in'] as num).toInt(),
      interval: (json['interval'] as num).toInt(),
    );
