import '../../api/scene_item.dart';
import 'base.dart';

/// Indicates a scene change
class SwitchScenesEvent extends BaseEvent {
  SwitchScenesEvent(Map<String, dynamic> json) : super(json);

  /// The new scene
  String get sceneName => this.json['scene-name'];

  /// List of scene items in the new scene. Same specification as GetCurrentScene.
  Iterable<SceneItem> get sources => (this.json['sources'] as List<dynamic>)
      .map((source) => SceneItem.fromJSON(source));
}
