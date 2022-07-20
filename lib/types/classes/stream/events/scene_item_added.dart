import 'base.dart';

/// A scene item has been added to a scene
class SceneItemAddedEvent extends BaseEvent {
  SceneItemAddedEvent(super.json);

  /// Name of the scene
  String get sceneName => this.json['scene-name'];

  /// Name of the item added to the scene
  String get itemName => this.json['item-name'];

  /// Scene item ID
  int get itemID => this.json['item-id'];
}
