import 'base.dart';

/// The current program scene has changed.
class CurrentProgramSceneChangedEvent extends BaseEvent {
  CurrentProgramSceneChangedEvent(super.json);

  /// Name of the scene that was switched to
  String get sceneName => this.json['sceneName'];
}
