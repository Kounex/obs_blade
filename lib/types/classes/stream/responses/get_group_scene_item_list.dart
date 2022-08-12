import 'package:obs_blade/types/classes/api/scene_item.dart';

import 'base.dart';

/// Basically GetSceneItemList, but for groups.
///
/// Using groups at all in OBS is discouraged, as they are very broken under the hood.
class GetGroupSceneItemListResponse extends BaseResponse {
  GetGroupSceneItemListResponse(super.json);

  /// Array of scene items in the group
  List<SceneItem> get sceneItems => (this.json['sceneItems'] as List<dynamic>)
      .map((sceneItem) => SceneItem.fromJSON(sceneItem))
      .toList();
}
