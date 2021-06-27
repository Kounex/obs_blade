import 'base.dart';

class SourceMuteStateChangedEvent extends BaseEvent {
  SourceMuteStateChangedEvent(Map<String, dynamic> json) : super(json);

  /// Source name
  String get sourceName => this.json['sourceName'];

  /// Mute status of the source
  bool get muted => this.json['muted'];
}
