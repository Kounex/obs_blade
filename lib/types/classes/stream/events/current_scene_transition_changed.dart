import 'package:obs_blade/types/classes/stream/events/base.dart';

/// The current scene transition has changed.
class CurrentSceneTransitionChangedEvent extends BaseEvent {
  CurrentSceneTransitionChangedEvent(super.json);

  /// Name of the new transition
  String get transitionName => this.json['transitionName'];
}
