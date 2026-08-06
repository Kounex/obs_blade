import 'package:freezed_annotation/freezed_annotation.dart';

part 'twitch_user_emote.freezed.dart';
part 'twitch_user_emote.g.dart';

/// One first-party emote the logged-in user can use in their own channel's
/// chat (Helix `chat/emotes/user` `data[]`). [emoteType]/[emoteSetId] are
/// kept as raw strings — Twitch's enum is open-ended and the picker's
/// grouping uses [ownerId] only, so unknown values must not crash parsing.
@Freezed(fromJson: true, toJson: false)
abstract class TwitchUserEmote with _$TwitchUserEmote {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory TwitchUserEmote({
    required String id,
    required String name,
    required String ownerId,
    @Default('') String emoteType,
    @Default('') String emoteSetId,
  }) = _TwitchUserEmote;

  factory TwitchUserEmote.fromJson(Map<String, Object?> json) =>
      _$TwitchUserEmoteFromJson(json);
}
