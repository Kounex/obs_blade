import 'base.dart';

/// A scene item's lock state has changed.
class SceneItemLockStateChangedEvent extends BaseEvent {
  SceneItemLockStateChangedEvent(super.json);

  /// Name of the scene the item is in
  String get sceneName => this.json['sceneName'];

  /// Numeric ID of the scene item
  int get sceneItemId => this.json['sceneItemId'];

  /// Whether the scene item is locked
  bool get sceneItemLocked => this.json['sceneItemLocked'];
}
