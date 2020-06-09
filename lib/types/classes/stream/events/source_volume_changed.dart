import 'base.dart';

/// The volume of a source has changed
class SourceVolumeChangedEvent extends BaseEvent {
  SourceVolumeChangedEvent(json) : super(json);

  /// Source name
  String get sourceName => this.json['sourceName'];

  /// Source volume
  double get volume => this.json['volume'];
}
