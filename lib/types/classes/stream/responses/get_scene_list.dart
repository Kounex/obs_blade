import '../../api/scene.dart';
import 'base.dart';

class GetSceneListResponse extends BaseResponse {
  GetSceneListResponse(Map<String, dynamic> json) : super(json);

  /// name of the currently active scene
  String get currentScene => this.json['current-scene'];

  /// ordered list of the current profile's scenes (See GetCurrentScene for more information)
  Iterable<Scene> get scenes => (this.json['scenes'] as List<dynamic>)
      .map((scene) => Scene.fromJSON(scene));
}
