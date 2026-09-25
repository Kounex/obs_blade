import 'base.dart';

/// The monitor type of an input has changed.
class InputAudioMonitorTypeChangedEvent extends BaseEvent {
  InputAudioMonitorTypeChangedEvent(super.json);

  /// Name of the input
  String get inputName => this.json['inputName'];

  /// New monitor type of the input
  String get monitorType => this.json['monitorType'];
}
