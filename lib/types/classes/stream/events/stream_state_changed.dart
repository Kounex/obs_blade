import 'base.dart';

/// The state of the stream output has changed.
class StreamStateChangedEvent extends BaseEvent {
  StreamStateChangedEvent(super.json);

  /// Whether the output is active
  bool get outputActive => this.json['outputActive'];

  /// The specific state of the output
  String get outputState => this.json['outputState'];
}
