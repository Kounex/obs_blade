import 'package:obs_blade/types/classes/api/scene_collection.dart';
import 'package:obs_blade/types/classes/stream/responses/base.dart';

class ListSceneCollectionsResponse extends BaseResponse {
  ListSceneCollectionsResponse(Map<String, dynamic> json) : super(json);

  /// Name of the currently active scene collection
  List<SceneCollection> get sceneCollections =>
      (this.json['scene-collections'] as List<dynamic>)
          .map((sceneCollection) => SceneCollection.fromJSON(sceneCollection))
          .toList();
}
