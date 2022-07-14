import '../../api/scene.dart';
import 'base.dart';

/// Get a list of scenes in the currently active profile
class GetSceneListResponse extends BaseResponse {
  GetSceneListResponse(super.json, super.newProtocol);

  /// Name of the currently active scene
  String get currentScene => this.json['current-scene'];

  /// Ordered list of the current profile's scenes (See GetCurrentScene for more information)
  Iterable<Scene> get scenes => (this.json['scenes'] as List<dynamic>)
      .map((scene) => Scene.fromJSON(scene));
}
