import 'package:obs_blade/types/classes/stream/batch_responses/base.dart';
import 'package:obs_blade/types/classes/stream/responses/get_scene_item_private_settings.dart';

class SceneItemPrivateSettingsBatchResponse extends BaseBatchResponse {
  SceneItemPrivateSettingsBatchResponse(super.json);

  Iterable<GetSceneItemPrivateSettingsResponse> get privateSettings => this
      .responses
      .map((response) => GetSceneItemPrivateSettingsResponse(response.jsonRAW));
}
