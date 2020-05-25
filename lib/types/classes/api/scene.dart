import 'package:flutter/material.dart';

import 'scene_item.dart';

class Scene {
  String name;
  List<SceneItem> sources;

  Scene({@required this.name, @required this.sources});

  static Scene fromJSON(Map<String, dynamic> fullJSON) => Scene(
      name: fullJSON['name'],
      sources: (fullJSON['sources'] as List<dynamic>)
          .map((source) => SceneItem.fromJSON(source))
          .toList());
}
