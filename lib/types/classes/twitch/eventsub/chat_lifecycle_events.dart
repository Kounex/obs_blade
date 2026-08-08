import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_lifecycle_events.freezed.dart';
part 'chat_lifecycle_events.g.dart';

/// `channel.chat.message_delete` event — a moderator removed one message.
/// [userName] is the deleting moderator's display name (the row's reveal
/// line consumes it). Twitch's actual payload carries no moderator field —
/// the fixture mirrors the documented example — so this is always null in
/// practice and only kept forward-compatible; other display fields are
/// deliberately not modeled.
@Freezed(fromJson: true, toJson: false)
abstract class ChatMessageDeleteEvent with _$ChatMessageDeleteEvent {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory ChatMessageDeleteEvent({
    required String messageId,
    required String targetUserId,
    String? userName,
  }) = _ChatMessageDeleteEvent;

  factory ChatMessageDeleteEvent.fromJson(Map<String, Object?> json) =>
      _$ChatMessageDeleteEventFromJson(json);
}

/// `channel.chat.clear_user_messages` event — a moderator/bot cleared all
/// messages from a specific user (timeout/ban purge).
@Freezed(fromJson: true, toJson: false)
abstract class ChatClearUserMessagesEvent with _$ChatClearUserMessagesEvent {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory ChatClearUserMessagesEvent({
    required String targetUserId,
  }) = _ChatClearUserMessagesEvent;

  factory ChatClearUserMessagesEvent.fromJson(Map<String, Object?> json) =>
      _$ChatClearUserMessagesEventFromJson(json);
}

/// `channel.chat.clear` event — a moderator/bot cleared the whole chat
/// room. The payload carries only broadcaster ids.
@Freezed(fromJson: true, toJson: false)
abstract class ChatClearEvent with _$ChatClearEvent {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory ChatClearEvent({
    required String broadcasterUserId,
  }) = _ChatClearEvent;

  factory ChatClearEvent.fromJson(Map<String, Object?> json) =>
      _$ChatClearEventFromJson(json);
}
