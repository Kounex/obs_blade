import 'base.dart';

/// An input's mute state has changed.
class InputMuteStateChangedEvent extends BaseEvent {
  InputMuteStateChangedEvent(super.json);

  /// Name of the input
  String get inputName => this.json['inputName'];

  /// Whether the input is muted
  bool get inputMuted => this.json['inputMuted'];
}
