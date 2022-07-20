import '../../../enums/event_type.dart';
import '../../../interfaces/message.dart';

/// Initial Wrapper object for an event which is received from the OBS WebSocket
class BaseEvent implements Message {
  @override
  Map<String, dynamic> jsonRAW;

  @override
  Map<String, dynamic> json;

  BaseEvent(Map<String, dynamic> json)
      : jsonRAW = json,
        json = json['d']['eventData'] ?? {};

  EventType? get eventType {
    try {
      return EventType.values.firstWhere(
        (eventType) => eventType.name == this.jsonRAW['d']['eventType'],
      );
    } catch (e) {
      return null;
    }
  }

  /// (Optional): time elapsed between now and stream start (only present if OBS Studio is streaming)
  ///
  /// OLD, < 4.X
  String? get streamTimecodeOld => this.json['stream-timecode'];

  /// (Optional): time elapsed between now and recording start (only present if OBS Studio is recording)
  ///
  /// OLD, < 4.X
  String? get recTimecodeOld => this.json['rec-timecode'];
}
