import 'package:freezed_annotation/freezed_annotation.dart';

part 'youtube_device_code.freezed.dart';
part 'youtube_device_code.g.dart';

/// RFC 8628 device authorization response from
/// `oauth2.googleapis.com/device/code`. Note Google uses
/// `verification_url` (not Twitch's `verification_uri`).
@Freezed(fromJson: true, toJson: false)
abstract class YouTubeDeviceCode with _$YouTubeDeviceCode {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory YouTubeDeviceCode({
    required String deviceCode,
    required String userCode,
    required String verificationUrl,
    required int expiresIn,
    required int interval,
  }) = _YouTubeDeviceCode;

  factory YouTubeDeviceCode.fromJson(Map<String, Object?> json) =>
      _$YouTubeDeviceCodeFromJson(json);
}
