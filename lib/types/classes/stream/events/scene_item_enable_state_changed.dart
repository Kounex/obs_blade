import 'base.dart';

/// A scene item's enable state has changed.
class SceneItemEnableStateChangedEvent extends BaseEvent {
  SceneItemEnableStateChangedEvent(super.json);

  /// Name of the scene the item is in
  String get sceneName => this.json['sceneName'];

  /// Numeric ID of the scene item
  int get sceneItemId => this.json['sceneItemId'];

  /// Whether the scene item is enabled (visible)
  bool get sceneItemEnabled => this.json['sceneItemEnabled'];
}
