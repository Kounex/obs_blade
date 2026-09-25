import 'base.dart';

/// The audio balance value of an input has changed.
class InputAudioBalanceChangedEvent extends BaseEvent {
  InputAudioBalanceChangedEvent(super.json);

  /// Name of the affected input
  String get inputName => this.json['inputName'];

  /// New audio balance value of the input
  double get inputAudioBalance =>
      (this.json['inputAudioBalance'] as num).toDouble();
}
