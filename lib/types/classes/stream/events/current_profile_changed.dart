import 'package:obs_blade/types/classes/stream/events/base.dart';

/// The current profile has changed.
class CurrentProfileChangedEvent extends BaseEvent {
  CurrentProfileChangedEvent(super.json);

  /// Name of the new profile
  String get profileName => this.json['profileName'];
}
