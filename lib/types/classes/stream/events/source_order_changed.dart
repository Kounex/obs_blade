import 'base.dart';

/// Scene items within a scene have been reordered
class SourceOrderChangedEvent extends BaseEvent {
  SourceOrderChangedEvent(super.json);

  /// Name of the scene where items have been reordered
  String get sceneName => this.json['scene-name'];

  /// Ordered list of scene items
  List<MetaSceneItem> get sceneItems =>
      (this.json['scene-items'] as List<dynamic>)
          .map((sceneItem) => MetaSceneItem.fromJSON(sceneItem))
          .toList();
}

class MetaSceneItem {
  /// Item source name
  final String sourceName;

  /// Scene item unique ID
  final int itemID;

  MetaSceneItem({required this.sourceName, required this.itemID});

  static MetaSceneItem fromJSON(Map<String, dynamic> json) {
    return MetaSceneItem(
        sourceName: json['source-name'], itemID: json['item-id']);
  }
}
