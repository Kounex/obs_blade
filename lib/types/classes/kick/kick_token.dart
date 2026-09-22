import 'package:freezed_annotation/freezed_annotation.dart';

part 'kick_token.freezed.dart';
part 'kick_token.g.dart';

/// Kick's token response carries the granted scopes as a single
/// space-separated string (like Google's) — tolerate a JSON array too.
List<String> _scopesFromJson(Object? value) => value is String
    ? value.split(' ').where((scope) => scope.isNotEmpty).toList()
    : value is List
    ? value.whereType<String>().toList()
    : const <String>[];

/// User access token response from `id.kick.com/oauth/token`
@Freezed(fromJson: true, toJson: false)
abstract class KickToken with _$KickToken {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory KickToken({
    required String accessToken,
    String? refreshToken,
    required int expiresIn,
    @JsonKey(fromJson: _scopesFromJson) @Default(<String>[]) List<String> scope,
    String? tokenType,
  }) = _KickToken;

  factory KickToken.fromJson(Map<String, Object?> json) =>
      _$KickTokenFromJson(json);
}
