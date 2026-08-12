import 'package:freezed_annotation/freezed_annotation.dart';

part 'channel_chat_message.freezed.dart';
part 'channel_chat_message.g.dart';

/// CDN URL for a chat emote (dark theme, mid size) — no API call needed.
String twitchEmoteUrl(String emoteId) =>
    'https://static-cdn.jtvnw.net/emoticons/v2/$emoteId/default/dark/2.0';

/// `channel.chat.message` event payload.
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
    /// Twitch message kind — `text`, `user_intro` (intro), etc.
    @Default('text') String messageType,
    ChatMessageReply? reply,

    /// From EventSub envelope `metadata.message_timestamp` — not on the
    /// chat event JSON. Stamped by [TwitchEventSubService] after parse.
    @JsonKey(includeFromJson: false, includeToJson: false) DateTime? receivedAt,

    /// First-time chatter highlight — from IRC `first-msg=1` (sidecar) or
    /// `message_type == user_intro`. Not on the EventSub chat JSON.
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(false)
    bool isFirstMessage,
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
    ChatFragmentMention? mention,
    ChatFragmentGif? gif,
  }) = _ChatMessageFragment;

  factory ChatMessageFragment.fromJson(Map<String, Object?> json) =>
      _$ChatMessageFragmentFromJson(json);
}

/// GIF picker attachment (`type == 'gif'`, added 2026-07) — [text] on the
/// fragment is the search term / title, [url] is the animated image.
@Freezed(fromJson: true, toJson: false)
abstract class ChatFragmentGif with _$ChatFragmentGif {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory ChatFragmentGif({
    required String gifId,
    required String url,
  }) = _ChatFragmentGif;

  factory ChatFragmentGif.fromJson(Map<String, Object?> json) =>
      _$ChatFragmentGifFromJson(json);
}

@Freezed(fromJson: true, toJson: false)
abstract class ChatFragmentEmote with _$ChatFragmentEmote {
  const factory ChatFragmentEmote({
    required String id,
  }) = _ChatFragmentEmote;

  factory ChatFragmentEmote.fromJson(Map<String, Object?> json) =>
      _$ChatFragmentEmoteFromJson(json);
}

/// Resolved `@mention` — Twitch already matched the login; color is not
/// on the wire (looked up from recent chatters in the store).
@Freezed(fromJson: true, toJson: false)
abstract class ChatFragmentMention with _$ChatFragmentMention {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory ChatFragmentMention({
    required String userId,
    required String userLogin,
    required String userName,
  }) = _ChatFragmentMention;

  factory ChatFragmentMention.fromJson(Map<String, Object?> json) =>
      _$ChatFragmentMentionFromJson(json);
}

/// Parent preview when this message is a threaded reply.
@Freezed(fromJson: true, toJson: false)
abstract class ChatMessageReply with _$ChatMessageReply {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory ChatMessageReply({
    required String parentMessageId,
    required String parentMessageBody,
    required String parentUserId,
    required String parentUserName,
    required String parentUserLogin,
    required String threadMessageId,
    required String threadUserId,
    required String threadUserName,
    required String threadUserLogin,
  }) = _ChatMessageReply;

  factory ChatMessageReply.fromJson(Map<String, Object?> json) =>
      _$ChatMessageReplyFromJson(json);
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
