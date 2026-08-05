import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/settings_keys.dart';

part 'twitch_chat_badges.freezed.dart';
part 'twitch_chat_badges.g.dart';

/// Maps a badge `set_id` to its visibility toggle. The dedicated toggles
/// cover the common roles; everything else (sub-gifter, staff, partner,
/// premium, event badges, ...) falls under [SettingsKeys.TwitchChatBadgeOther].
SettingsKeys settingsKeyForBadgeSetId(String setId) => switch (setId) {
      'broadcaster' => SettingsKeys.TwitchChatBadgeBroadcaster,
      'moderator' => SettingsKeys.TwitchChatBadgeModerator,
      'vip' => SettingsKeys.TwitchChatBadgeVip,
      'subscriber' => SettingsKeys.TwitchChatBadgeSubscriber,
      'founder' => SettingsKeys.TwitchChatBadgeFounder,
      'bits' => SettingsKeys.TwitchChatBadgeBits,
      _ => SettingsKeys.TwitchChatBadgeOther,
    };

/// One badge set of the helix `chat/badges` responses (`data[]`)
@Freezed(fromJson: true, toJson: false)
abstract class TwitchBadgeSet with _$TwitchBadgeSet {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory TwitchBadgeSet({
    required String setId,
    @Default(<TwitchBadgeVersion>[]) List<TwitchBadgeVersion> versions,
  }) = _TwitchBadgeSet;

  factory TwitchBadgeSet.fromJson(Map<String, Object?> json) =>
      _$TwitchBadgeSetFromJson(json);
}

/// One version of a badge set (subscriber tenure, bits tier, ...)
@Freezed(fromJson: true, toJson: false)
abstract class TwitchBadgeVersion with _$TwitchBadgeVersion {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory TwitchBadgeVersion({
    required String id,
    // Helix uses `image_url_Nx`; FieldRename.snake would produce
    // `image_urlNx`, so these keys need explicit names.
    @JsonKey(name: 'image_url_1x') required String imageUrl1x,
    @JsonKey(name: 'image_url_2x') required String imageUrl2x,
    @JsonKey(name: 'image_url_4x') required String imageUrl4x,
    String? title,
  }) = _TwitchBadgeVersion;

  factory TwitchBadgeVersion.fromJson(Map<String, Object?> json) =>
      _$TwitchBadgeVersionFromJson(json);
}
