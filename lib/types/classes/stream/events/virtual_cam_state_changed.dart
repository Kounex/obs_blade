import 'base.dart';

/// The state of the virtualcam output has changed.
class VirtualCamStateChangedEvent extends BaseEvent {
  VirtualCamStateChangedEvent(super.json);

  /// Whether the output is active
  bool get outputActive => this.json['outputActive'];

  /// The specific state of the output
  String get outputState => this.json['outputState'];
}
