import '../../../enums/event_type.dart';
import '../../../interfaces/message.dart';

/// Initial Wrapper object for an event which is received from the OBS WebSocket
class BaseEvent implements Message {
  Map<String, dynamic> json;

  BaseEvent(this.json);

  /// The type of the event
  String get updateType => this.json['update-type'];

  /// (Optional): time elapsed between now and stream start (only present if OBS Studio is streaming)
  String? get streamTimecode => this.json['stream-timecode'];

  /// (Optional): time elapsed between now and recording start (only present if OBS Studio is recording)
  String? get recTimecode => this.json['rec-timecode'];

  EventType? get eventType {
    try {
      return EventType.values.firstWhere(
        (eventType) => eventType.toString().split('.')[1] == this.updateType,
      );
    } catch (e) {
      return null;
    }
  }
}
