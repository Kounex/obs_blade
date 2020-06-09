import 'base.dart';

class SourceMuteStateChangedEvent extends BaseEvent {
  SourceMuteStateChangedEvent(json) : super(json);

  /// Source name
  String get sourceName => this.json['sourceName'];

  /// Mute status of the source
  bool get muted => this.json['muted'];
}
