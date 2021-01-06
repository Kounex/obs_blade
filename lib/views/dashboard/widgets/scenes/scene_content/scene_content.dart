import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/base_card.dart';

import 'audio_inputs/audio_inputs.dart';
import 'scene_items/scene_items.dart';

class SceneContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Flexible(
          child: BaseCard(
            title: 'Scene Items',
            rightPadding: 12,
            paddingChild: EdgeInsets.all(0),
            child: SizedBox(
              height: 350.0,
              child: SceneItems(),
            ),
          ),
        ),
        Flexible(
          child: BaseCard(
            title: 'Audio',
            leftPadding: 12,
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
