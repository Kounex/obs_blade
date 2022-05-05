import '../../api/scene_collection.dart';

import 'base.dart';

/// Triggered when a scene collection is created, added, renamed, or removed
class SceneCollectionListChangedEvent extends BaseEvent {
  SceneCollectionListChangedEvent(Map<String, dynamic> json) : super(json);

  /// Scene collections list.
  List<SceneCollection> get sceneCollections =>
      (this.json['sceneCollections'] as List<dynamic>)
          .map((sceneCollection) =>
              SceneCollection.fromJSON({'sc-name': sceneCollection['name']}))
          .toList();
}
