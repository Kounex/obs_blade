import 'base.dart';

/// A scene item's enable state has changed.
class SceneItemEnableStateChangedEvent extends BaseEvent {
  SceneItemEnableStateChangedEvent(super.json);

  /// Name of the scene the item is in
  String get sceneName => this.json['sceneName'];

  /// UUID of the scene the item is in - null on obs-websocket < 5.1
  String? get sceneUuid => this.json['sceneUuid'] as String?;

  /// Numeric ID of the scene item
  int get sceneItemId => this.json['sceneItemId'];

  /// Whether the scene item is enabled (visible)
  bool get sceneItemEnabled => this.json['sceneItemEnabled'];
}
