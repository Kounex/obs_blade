import 'base.dart';

/// Studio Mode has been enabled or disabled
class StudioModeSwitchedEvent extends BaseEvent {
  StudioModeSwitchedEvent(json) : super(json);

  /// The new enabled state of Studio Mode
  bool get newState => this.json['new-state'];
}
