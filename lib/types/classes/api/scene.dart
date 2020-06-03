import 'package:flutter/material.dart';

import 'scene_item.dart';

class Scene {
  /// Name of the currently active scene
  String name;

  /// Ordered list of the current scene's source items
  List<SceneItem> sources;

  Scene({
    @required this.name,
    @required this.sources,
  });

  static Scene fromJSON(Map<String, dynamic> json) => Scene(
        name: json['name'],
        sources: (json['sources'] as List<dynamic>)
            .map((source) => SceneItem.fromJSON(source))
            .toList(),
      );
}
