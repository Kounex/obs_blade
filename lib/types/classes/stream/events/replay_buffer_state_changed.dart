import 'base.dart';

/// The state of the replay buffer output has changed.
class ReplayBufferStateChangedEvent extends BaseEvent {
  ReplayBufferStateChangedEvent(super.json);

  /// Whether the output is active
  bool get outputActive => this.json['outputActive'];

  /// The specific state of the output
  String get outputState => this.json['outputState'];
}
