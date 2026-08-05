import 'package:freezed_annotation/freezed_annotation.dart';

part 'channel_chat_message.freezed.dart';
part 'channel_chat_message.g.dart';

/// CDN URL for a chat emote (dark theme, mid size) — no API call needed.
String twitchEmoteUrl(String emoteId) =>
    'https://static-cdn.jtvnw.net/emoticons/v2/$emoteId/default/dark/2.0';

/// `channel.chat.message` event payload. Cheer/reply are parsed by
/// Twitch's schema but intentionally not modeled.
@Freezed(fromJson: true, toJson: false)
abstract class ChatMessageEvent with _$ChatMessageEvent {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory ChatMessageEvent({
    required String broadcasterUserId,
    required String chatterUserId,
    required String chatterUserLogin,
    required String chatterUserName,
    required String messageId,
    required ChatMessageText message,
    String? color,
    @Default(<ChatMessageBadge>[]) List<ChatMessageBadge> badges,
  }) = _ChatMessageEvent;

  factory ChatMessageEvent.fromJson(Map<String, Object?> json) =>
      _$ChatMessageEventFromJson(json);
}

@Freezed(fromJson: true, toJson: false)
abstract class ChatMessageText with _$ChatMessageText {
  const factory ChatMessageText({
    required String text,
    @Default(<ChatMessageFragment>[]) List<ChatMessageFragment> fragments,
  }) = _ChatMessageText;

  factory ChatMessageText.fromJson(Map<String, Object?> json) =>
      _$ChatMessageTextFromJson(json);
}

@Freezed(fromJson: true, toJson: false)
abstract class ChatMessageFragment with _$ChatMessageFragment {
  const factory ChatMessageFragment({
    required String type,
    required String text,
    ChatFragmentEmote? emote,
  }) = _ChatMessageFragment;

  factory ChatMessageFragment.fromJson(Map<String, Object?> json) =>
      _$ChatMessageFragmentFromJson(json);
}

@Freezed(fromJson: true, toJson: false)
abstract class ChatFragmentEmote with _$ChatFragmentEmote {
  const factory ChatFragmentEmote({
    required String id,
  }) = _ChatFragmentEmote;

  factory ChatFragmentEmote.fromJson(Map<String, Object?> json) =>
      _$ChatFragmentEmoteFromJson(json);
}

/// One entry of the payload's `badges` array: the exact lookup key for
/// the badge catalogs is (`setId`, `id`); `info` is set-specific metadata
/// (e.g. subscriber tenure months) and often empty.
@Freezed(fromJson: true, toJson: false)
abstract class ChatMessageBadge with _$ChatMessageBadge {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory ChatMessageBadge({
    required String setId,
    required String id,
    @Default('') String info,
  }) = _ChatMessageBadge;

  factory ChatMessageBadge.fromJson(Map<String, Object?> json) =>
      _$ChatMessageBadgeFromJson(json);
}
