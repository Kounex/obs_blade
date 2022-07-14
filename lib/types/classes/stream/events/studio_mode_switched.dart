import 'base.dart';

/// Studio Mode has been enabled or disabled
class StudioModeSwitchedEvent extends BaseEvent {
  StudioModeSwitchedEvent(super.json, super.newProtocol);

  /// The new enabled state of Studio Mode
  bool get newState => this.json['new-state'];
}
