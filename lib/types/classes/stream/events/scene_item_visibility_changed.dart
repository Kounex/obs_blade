import 'base.dart';

/// A transition (other than "cut") has begun
class SceneItemVisibilityChangedEvent extends BaseEvent {
  SceneItemVisibilityChangedEvent(Map<String, dynamic> json) : super(json);

  /// Name of the scene
  String get sceneName => this.json['scene-name'];

  /// Name of the item in the scene
  String get itemName => this.json['item-name'];

  /// Scene item ID
  int get itemID => this.json['item-id'];

  /// New visibility state of the item
  bool get itemVisible => this.json['item-visible'];
}
