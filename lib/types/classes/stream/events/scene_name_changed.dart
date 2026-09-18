import 'base.dart';

/// The name of a scene has changed.
class SceneNameChangedEvent extends BaseEvent {
  SceneNameChangedEvent(super.json);

  /// UUID of the scene that was renamed
  String get sceneUuid => this.json['sceneUuid'];

  /// Old name of the scene
  String get oldSceneName => this.json['oldSceneName'];

  /// New name of the scene
  String get sceneName => this.json['sceneName'];
}
