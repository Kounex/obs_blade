import 'package:freezed_annotation/freezed_annotation.dart';

part 'twitch_user.freezed.dart';
part 'twitch_user.g.dart';

/// Entry of the helix `/users` response (`data[0]`)
@Freezed(fromJson: true, toJson: false)
abstract class TwitchUser with _$TwitchUser {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory TwitchUser({
    required String id,
    required String login,
    String? displayName,
    String? profileImageUrl,
  }) = _TwitchUser;

  factory TwitchUser.fromJson(Map<String, Object?> json) =>
      _$TwitchUserFromJson(json);
}
