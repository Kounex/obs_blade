import 'base.dart';

/// Studio mode has been enabled or disabled.
class StudioModeStateChangedEvent extends BaseEvent {
  StudioModeStateChangedEvent(super.json);

  /// True == Enabled, False == Disabled
  bool get studioModeEnabled => this.json['studioModeEnabled'];
}
