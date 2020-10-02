import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/base_card.dart';

import 'audio_inputs/audio_inputs.dart';
import 'scene_items/scene_items.dart';

class SceneContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: BaseCard(
            title: 'Scene Items',
            paddingChild: EdgeInsets.all(0),
            child: SizedBox(
              height: 350.0,
              child: SceneItems(),
            ),
          ),
        ),
        Expanded(
          child: BaseCard(
            title: 'Audio',
            paddingChild: EdgeInsets.all(0),
            child: SizedBox(
              height: 350.0,
              child: AudioInputs(),
            ),
          ),
        ),
      ],
    );
  }
}
