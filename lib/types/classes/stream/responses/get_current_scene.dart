import '../../api/scene_item.dart';
import 'base.dart';

/// Get the current scene's name and source items
class GetCurrentSceneResponse extends BaseResponse {
  GetCurrentSceneResponse(Map<String, dynamic> json) : super(json);

  /// Name of the currently active scene
  String get name => this.json['name'];

  /// Ordered list of the current scene's source items
  List<SceneItem> get sources => (this.json['sources'] as List<dynamic>)
      .map((source) => SceneItem.fromJSON(source))
      .toList();
}
