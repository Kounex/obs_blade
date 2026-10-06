import 'base.dart';

/// `SceneTransitionStarted` / `SceneTransitionEnded` /
/// `SceneTransitionVideoEnded` - they only name the transition (the one
/// really running, so a per-scene override shows here), not the scenes
class SceneTransitionEvent extends BaseEvent {
  SceneTransitionEvent(super.json);

  /// Name of the transition
  String? get transitionName => this.json['transitionName'];

  /// UUID of the transition
  String? get transitionUuid => this.json['transitionUuid'];
}
