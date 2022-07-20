import 'package:obs_blade/types/classes/api/scene_item.dart';

import 'base.dart';

/// Gets a list of all scene items in a scene.
class GetSceneItemListResponse extends BaseResponse {
  GetSceneItemListResponse(super.json);

  /// Array of scene items in the scene
  Iterable<SceneItem> get sceneItems =>
      (this.json['sceneItems'] as List<dynamic>)
          .map((sceneItem) => SceneItem.fromJSON(sceneItem));
}
