import 'package:freezed_annotation/freezed_annotation.dart';

part 'twitch_device_code.freezed.dart';
part 'twitch_device_code.g.dart';

/// RFC 8628 device authorization response from `id.twitch.tv/oauth2/device`
@Freezed(fromJson: true, toJson: false)
abstract class TwitchDeviceCode with _$TwitchDeviceCode {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory TwitchDeviceCode({
    required String deviceCode,
    required String userCode,
    required String verificationUri,
    required int expiresIn,
    required int interval,
  }) = _TwitchDeviceCode;

  factory TwitchDeviceCode.fromJson(Map<String, Object?> json) =>
      _$TwitchDeviceCodeFromJson(json);
}
