import 'base.dart';

/// A scene item has been removed from a scene
class SceneItemRemovedEvent extends BaseEvent {
  SceneItemRemovedEvent(super.json);

  /// Name of the scene
  String get sceneName => this.json['scene-name'];

  /// Name of the item removed from the scene
  String get itemName => this.json['item-name'];

  /// Scene item ID
  int get itemID => this.json['item-id'];
}
