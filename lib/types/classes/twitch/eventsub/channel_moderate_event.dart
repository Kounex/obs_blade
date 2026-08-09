import 'package:freezed_annotation/freezed_annotation.dart';

part 'channel_moderate_event.freezed.dart';
part 'channel_moderate_event.g.dart';

/// `channel.moderate` v2 event — a moderator performed an action in the
/// channel. Delete / timeout / ban (and shared-chat twins) are modeled for
/// tombstone markers + actor reveal; every other action parses-then-ignores.
/// Flat envelope: an `action` discriminator plus every action field present,
/// all but the active one null (see the fixtures).
@Freezed(fromJson: true, toJson: false)
abstract class ChannelModerateEvent with _$ChannelModerateEvent {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory ChannelModerateEvent({
    required String action,
    required String moderatorUserName,
    ModerateDeleteAction? delete,
    ModerateTimeoutAction? timeout,
    ModerateBanAction? ban,
    ModerateDeleteAction? sharedChatDelete,
    ModerateTimeoutAction? sharedChatTimeout,
    ModerateBanAction? sharedChatBan,
  }) = _ChannelModerateEvent;

  factory ChannelModerateEvent.fromJson(Map<String, Object?> json) =>
      _$ChannelModerateEventFromJson(json);
}

/// The `delete` action payload — [messageId] keys the tombstone;
/// [userName] is the chatter (the row already renders their name).
@Freezed(fromJson: true, toJson: false)
abstract class ModerateDeleteAction with _$ModerateDeleteAction {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory ModerateDeleteAction({
    required String messageId,
    String? userName,
  }) = _ModerateDeleteAction;

  factory ModerateDeleteAction.fromJson(Map<String, Object?> json) =>
      _$ModerateDeleteActionFromJson(json);
}

/// The `timeout` action payload — [userId] keys the purge;
/// [expiresAt] yields the timed-out duration for the marker.
@Freezed(fromJson: true, toJson: false)
abstract class ModerateTimeoutAction with _$ModerateTimeoutAction {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory ModerateTimeoutAction({
    required String userId,
    String? userName,
    String? reason,
    required DateTime expiresAt,
  }) = _ModerateTimeoutAction;

  factory ModerateTimeoutAction.fromJson(Map<String, Object?> json) =>
      _$ModerateTimeoutActionFromJson(json);
}

/// The `ban` action payload — [userId] keys the purge.
@Freezed(fromJson: true, toJson: false)
abstract class ModerateBanAction with _$ModerateBanAction {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory ModerateBanAction({
    required String userId,
    String? userName,
    String? reason,
  }) = _ModerateBanAction;

  factory ModerateBanAction.fromJson(Map<String, Object?> json) =>
      _$ModerateBanActionFromJson(json);
}
