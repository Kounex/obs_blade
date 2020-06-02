import '../../api/scene_item.dart';
import 'base.dart';

class SwitchScenesEvent extends BaseEvent {
  SwitchScenesEvent(json) : super(json);

  /// the new scene
  String get sceneName => this.json['scene-name'];

  /// list of scene items in the new scene. same specification as GetCurrentScene.
  Iterable<SceneItem> get sources => (this.json['sources'] as List<dynamic>)
      .map((source) => SceneItem.fromJSON(source));
}
