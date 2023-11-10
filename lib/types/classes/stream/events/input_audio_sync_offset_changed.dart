import 'package:obs_blade/types/classes/stream/events/base.dart';

/// The sync offset of an input has changed.
class InputAudioSyncOffsetChangedEvent extends BaseEvent {
  InputAudioSyncOffsetChangedEvent(super.json);

  /// Name of the input
  String get inputName => this.json['inputName'];

  /// New sync offset in milliseconds
  int get inputAudioSyncOffset => this.json['inputAudioSyncOffset'];
}
