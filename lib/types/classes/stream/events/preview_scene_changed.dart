import '../../api/scene_item.dart';
import 'base.dart';

/// The selected preview scene has changed (only available in Studio Mode)
class PreviewSceneChangedEvent extends BaseEvent {
  PreviewSceneChangedEvent(super.json, super.newProtocol);

  /// Name of the scene being previewed
  String get sceneName => this.json['scene-name'];

  /// List of sources composing the scene. Same specification as [GetCurrentScene]
  List<SceneItem> get sources => List.from(
      this.json['sources'].map((sceneItem) => SceneItem.fromJSON(sceneItem)));
}
