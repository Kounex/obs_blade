import 'package:obs_blade/types/classes/api/scene_item.dart';

import 'base.dart';

/// A scene's item list has been reindexed.
class SceneItemListReindexedEvent extends BaseEvent {
  SceneItemListReindexedEvent(super.json);

  /// Name of the scene
  String get sceneName => this.json['sceneName'];

  /// Array of scene item objects
  List<SceneItem> get sceneItems => (this.json['sceneItems'] as List<dynamic>)
      .map((sceneItem) => SceneItem.fromJSON(sceneItem))
      .toList();
}
