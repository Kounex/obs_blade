class Scene {
  /// Name of the currently active scene
  String sceneName;

  /// Ordered list of the current scene's source items
  int sceneIndex;

  Scene({
    required this.sceneName,
    required this.sceneIndex,
  });

  static Scene fromJSON(Map<String, dynamic> json) => Scene(
        sceneName: json['sceneName'],
        sceneIndex: json['sceneIndex'],
      );
}
