import '../../../enums/event_type.dart';

class BaseEvent {
  Map<String, dynamic> json;

  BaseEvent(this.json);

  /// The type of the event
  EventType get updateType => this.instance(this.json['update-type']);

  /// (Optional): time elapsed between now and stream start (only present if OBS Studio is streaming)
  String get streamTimecode => this.json['stream-timecode'];

  /// (Optional): time elapsed between now and recording start (only present if OBS Studio is recording)
  String get recTimecode => this.json['rec-timecode'];

  EventType instance(String updateType) => EventType.values.firstWhere(
      (eventType) => eventType.toString().split('.')[1] == updateType,
      orElse: () => null);
  //   switch (updateType) {
  //     case 'StreamStarted':
  //       return EventType.StreamStarted;
  //     case 'StreamStopping':
  //       return EventType.StreamStopping;
  //     case 'StreamStatus':
  //       return EventType.StreamStatus;
  //     case 'ScenesChanged':
  //       return EventType.ScenesChanged;
  //     case 'SwitchScenes':
  //       return EventType.SwitchScenes;
  //     case 'TransitionBegin':
  //       return EventType.TransitionBegin;
  //     case 'SourceVolumeChanged':
  //       return EventType.SourceVolumeChanged;
  //     case 'SourceMuteStateChanged':
  //       return EventType.SourceMuteStateChanged;
  //     case 'Exiting':
  //       return EventType.Exiting;
  //     default:
  //       return null;
  //   }
  // }
}
