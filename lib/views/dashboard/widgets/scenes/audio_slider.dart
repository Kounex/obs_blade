import 'package:flutter/material.dart';

import '../../../../types/classes/api/scene_item.dart';

class AudioSlider extends StatelessWidget {
  final SceneItem audioSceneItem;

  AudioSlider({@required this.audioSceneItem});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(this.audioSceneItem.name),
        Slider(
          min: 0.0,
          max: 1.0,
          value: this.audioSceneItem.volume,
          onChanged: (volume) => {},
        ),
      ],
    );
  }
}
