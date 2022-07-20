import 'base.dart';

/// An input's volume level has changed.
class InputVolumeChangedEvent extends BaseEvent {
  InputVolumeChangedEvent(super.json);

  /// Name of the input
  String get inputName => this.json['inputName'];

  /// New volume level in multimap
  double get inputVolumeMul => this.json['inputVolumeMul'];

  /// New volume level in dB
  double get inputVolumeDb => this.json['inputVolumeDb'];
}
