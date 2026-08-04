import 'package:freezed_annotation/freezed_annotation.dart';

part 'eventsub_envelope.freezed.dart';
part 'eventsub_envelope.g.dart';

/// Envelope of every EventSub WebSocket message. Only the fields the app
/// needs are modeled — `payload` stays raw and is interpreted by the
/// caller based on [EventSubMetadata.messageType] / `subscriptionType`.
@Freezed(fromJson: true, toJson: false)
abstract class EventSubEnvelope with _$EventSubEnvelope {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory EventSubEnvelope({
    required EventSubMetadata metadata,
    required Map<String, Object?> payload,
  }) = _EventSubEnvelope;

  factory EventSubEnvelope.fromJson(Map<String, Object?> json) =>
      _$EventSubEnvelopeFromJson(json);
}

@Freezed(fromJson: true, toJson: false)
abstract class EventSubMetadata with _$EventSubMetadata {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory EventSubMetadata({
    required String messageId,
    required String messageType,
    String? subscriptionType,
  }) = _EventSubMetadata;

  factory EventSubMetadata.fromJson(Map<String, Object?> json) =>
      _$EventSubMetadataFromJson(json);
}
