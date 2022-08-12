import 'base.dart';

/// A scene item has been created.
class SceneItemAddedEvent extends BaseEvent {
  SceneItemAddedEvent(super.json);

  /// Name of the scene the item was added to
  String get sceneName => this.json['sceneName'];

  /// Name of the underlying source (input/scene)
  String get sourceName => this.json['sourceName'];

  /// Numeric ID of the scene item
  int get sceneItemId => this.json['sceneItemId'];

  /// Index position of the item
  int get sceneItemIndex => this.json['sceneItemIndex'];
}
