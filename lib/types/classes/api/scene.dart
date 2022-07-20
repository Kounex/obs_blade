import 'scene_item.dart';

class Scene {
  /// Name of the currently active scene
  String sceneName;

  /// Ordered list of the current scene's source items
  List<SceneItem> sources;

  Scene({
    required this.sceneName,
    this.sources = const [],
  });

  static Scene fromJSON(Map<String, dynamic> json) => Scene(
        sceneName: json['sceneName'],
      );
}
