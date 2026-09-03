// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'youtube_device_code.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_YouTubeDeviceCode _$YouTubeDeviceCodeFromJson(Map<String, dynamic> json) =>
    _YouTubeDeviceCode(
      deviceCode: json['device_code'] as String,
      userCode: json['user_code'] as String,
      verificationUrl: json['verification_url'] as String,
      expiresIn: (json['expires_in'] as num).toInt(),
      interval: (json['interval'] as num).toInt(),
    );
