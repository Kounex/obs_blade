// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'eventsub_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EventSubEnvelope _$EventSubEnvelopeFromJson(Map<String, dynamic> json) =>
    _EventSubEnvelope(
      metadata: EventSubMetadata.fromJson(
        json['metadata'] as Map<String, dynamic>,
      ),
      payload: json['payload'] as Map<String, dynamic>,
    );

_EventSubMetadata _$EventSubMetadataFromJson(Map<String, dynamic> json) =>
    _EventSubMetadata(
      messageId: json['message_id'] as String,
      messageType: json['message_type'] as String,
      messageTimestamp: _messageTimestampFromJson(json['message_timestamp']),
      subscriptionType: json['subscription_type'] as String?,
    );
