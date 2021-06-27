class SceneCollection {
  /// Name of the scene collection
  String scName;

  SceneCollection({required this.scName});

  static SceneCollection fromJSON(Map<String, dynamic> json) {
    return SceneCollection(scName: json['sc-name']);
  }
}
