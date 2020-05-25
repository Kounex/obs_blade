import '../../api/scene.dart';
import 'base.dart';

class GetSceneListResponse extends BaseResponse {
  GetSceneListResponse(Map<String, dynamic> json) : super(json);

  String get currentScene => this.json['current-scene'];

  Iterable<Scene> get scenes => (this.json['scenes'] as List<dynamic>)
      .map((scene) => Scene.fromJSON(scene));
}
