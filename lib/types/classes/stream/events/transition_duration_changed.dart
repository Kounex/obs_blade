import 'base.dart';

/// The current scene transition duration has changed.
class CurrentSceneTransitionDurationChangedEvent extends BaseEvent {
  CurrentSceneTransitionDurationChangedEvent(super.json);

  /// Transition duration in milliseconds
  int get transitionDuration => this.json['transitionDuration'];
}
