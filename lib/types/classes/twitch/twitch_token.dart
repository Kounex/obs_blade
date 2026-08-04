import 'package:freezed_annotation/freezed_annotation.dart';

part 'twitch_token.freezed.dart';
part 'twitch_token.g.dart';

/// User access token response from `id.twitch.tv/oauth2/token`
@Freezed(fromJson: true, toJson: false)
abstract class TwitchToken with _$TwitchToken {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory TwitchToken({
    required String accessToken,
    String? refreshToken,
    required int expiresIn,
    @Default(<String>[]) List<String> scope,
    String? tokenType,
  }) = _TwitchToken;

  factory TwitchToken.fromJson(Map<String, Object?> json) =>
      _$TwitchTokenFromJson(json);
}
