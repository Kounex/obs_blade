import 'base.dart';

/// The name of an input has changed.
class InputNameChangedEvent extends BaseEvent {
  InputNameChangedEvent(super.json);

  /// Old name of the input
  String get oldInputName => this.json['oldInputName'];

  /// New name of the input
  String get inputName => this.json['inputName'];
}
