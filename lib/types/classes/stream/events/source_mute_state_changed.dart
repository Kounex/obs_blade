import 'base.dart';

class SourceMuteStateChangedEvent extends BaseEvent {
  SourceMuteStateChangedEvent(super.json, super.newProtocol);

  /// Source name
  String get sourceName => this.json['sourceName'];

  /// Mute status of the source
  bool get muted => this.json['muted'];
}
