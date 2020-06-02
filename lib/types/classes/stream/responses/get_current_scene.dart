import '../../api/scene_item.dart';
import 'base.dart';

class GetCurrentSceneResponse extends BaseResponse {
  GetCurrentSceneResponse(json) : super(json);

  /// name of the currently active scene
  String get name => this.json['name'];

  /// ordered list of the current scene's source items
  Iterable<SceneItem> get sources => (this.json['sources'] as List<dynamic>)
      .map((source) => SceneItem.fromJSON(source));
}
