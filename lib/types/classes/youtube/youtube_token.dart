import 'package:freezed_annotation/freezed_annotation.dart';

part 'youtube_token.freezed.dart';
part 'youtube_token.g.dart';

/// Google's token response carries the granted scopes as a single
/// space-separated string (unlike Twitch's JSON array).
List<String> _scopesFromJson(Object? value) => value is String
    ? value.split(' ').where((scope) => scope.isNotEmpty).toList()
    : const <String>[];

/// User access token response from `oauth2.googleapis.com/token`
@Freezed(fromJson: true, toJson: false)
abstract class YouTubeToken with _$YouTubeToken {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory YouTubeToken({
    required String accessToken,
    String? refreshToken,
    required int expiresIn,
    @JsonKey(fromJson: _scopesFromJson) @Default(<String>[]) List<String> scope,
    String? tokenType,
  }) = _YouTubeToken;

  factory YouTubeToken.fromJson(Map<String, Object?> json) =>
      _$YouTubeTokenFromJson(json);
}
