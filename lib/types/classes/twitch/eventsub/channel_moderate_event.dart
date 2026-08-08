import 'package:freezed_annotation/freezed_annotation.dart';

part 'channel_moderate_event.freezed.dart';
part 'channel_moderate_event.g.dart';

/// `channel.moderate` v2 event — a moderator performed an action in the
/// channel. Only the `delete` action is modeled (tombstone actor reveal);
/// every other action parses-then-ignores. The real payload is a flat
/// envelope: an `action` discriminator plus every action field present,
/// all but the active one null (see the fixtures, which mirror the
/// twitch-rs v2 shape).
@Freezed(fromJson: true, toJson: false)
abstract class ChannelModerateEvent with _$ChannelModerateEvent {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory ChannelModerateEvent({
    required String action,
    required String moderatorUserName,
    ModerateDeleteAction? delete,
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
