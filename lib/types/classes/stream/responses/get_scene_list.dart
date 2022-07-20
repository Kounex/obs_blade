import '../../api/scene.dart';
import 'base.dart';

/// Gets an array of all scenes in OBS.
class GetSceneListResponse extends BaseResponse {
  GetSceneListResponse(super.json);

  /// Current program scene
  String get currentProgramSceneName => this.json['currentProgramSceneName'];

  /// Current preview scene. null if not in studio mode
  String? get currentPreviewSceneName => this.json['currentPreviewSceneName'];

  /// Ordered list of the current profile's scenes (See GetCurrentScene for more information)
  Iterable<Scene> get scenes => (this.json['scenes'] as List<dynamic>)
      .map((scene) => Scene.fromJSON(scene));
}
