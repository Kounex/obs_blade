import 'package:freezed_annotation/freezed_annotation.dart';

part 'automod_events.freezed.dart';
part 'automod_events.g.dart';

/// `automod.message.hold` v2 event — AutoMod (or a public blocked term)
/// caught a message; it sits in the queue until a moderator allows or
/// denies it (v1 is legacy and carries a different `message` shape — the
/// subscription pins version 2). Slim on purpose: only what the queue row
/// renders is modeled (fragments/boundaries dropped).
@Freezed(fromJson: true, toJson: false)
abstract class AutoModMessageHoldEvent with _$AutoModMessageHoldEvent {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory AutoModMessageHoldEvent({
    required String messageId,
    required String userId,
    required String userLogin,
    required String userName,
    required AutoModMessageContent message,

    /// `automod` or `blocked_term` — which filter caught the message.
    required String reason,

    /// AutoMod classification — null when [reason] is `blocked_term`.
    AutoModClassification? automod,
    DateTime? heldAt,
  }) = _AutoModMessageHoldEvent;

  factory AutoModMessageHoldEvent.fromJson(Map<String, Object?> json) =>
      _$AutoModMessageHoldEventFromJson(json);
}

/// The held message's content — v2 nests it (`message.text` + fragments).
@Freezed(fromJson: true, toJson: false)
abstract class AutoModMessageContent with _$AutoModMessageContent {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory AutoModMessageContent({
    required String text,
  }) = _AutoModMessageContent;

  factory AutoModMessageContent.fromJson(Map<String, Object?> json) =>
      _$AutoModMessageContentFromJson(json);
}

/// The `automod` block of a hold/update event — category + level of the
/// matched filter (e.g. `aggressive`, 3).
@Freezed(fromJson: true, toJson: false)
abstract class AutoModClassification with _$AutoModClassification {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory AutoModClassification({
    String? category,
    int? level,
  }) = _AutoModClassification;

  factory AutoModClassification.fromJson(Map<String, Object?> json) =>
      _$AutoModClassificationFromJson(json);
}

/// `automod.message.update` v2 event — a held message was resolved
/// (`approved` / `denied` / `expired`), by us or another mod. The queue
/// only needs [messageId] to drop the row; [status] distinguishes the
/// outcome for logging.
@Freezed(fromJson: true, toJson: false)
abstract class AutoModMessageUpdateEvent with _$AutoModMessageUpdateEvent {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory AutoModMessageUpdateEvent({
    required String messageId,
    required String status,
  }) = _AutoModMessageUpdateEvent;

  factory AutoModMessageUpdateEvent.fromJson(Map<String, Object?> json) =>
      _$AutoModMessageUpdateEventFromJson(json);
}
