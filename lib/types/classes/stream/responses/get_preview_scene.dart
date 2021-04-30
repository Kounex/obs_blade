import '../../api/scene_item.dart';
import 'base.dart';

/// Get the name of the currently previewed scene and its list of sources. Will return an error if Studio Mode is not enabled
class GetPreviewSceneResponse extends BaseResponse {
  GetPreviewSceneResponse(json) : super(json);

  /// The name of the active preview scene
  String get name => this.json['name'];

  /// Ordered list of the preview scene's source items
  Iterable<SceneItem> get sources => (this.json['sources'] as List<dynamic>)
      .map((source) => SceneItem.fromJSON(source));
}
