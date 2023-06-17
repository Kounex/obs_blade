import 'package:flutter/material.dart';

import '../../../../../shared/general/base/card.dart';
import 'audio_inputs/audio_inputs.dart';
import 'scene_items/scene_items.dart';

class SceneContent extends StatelessWidget {
  const SceneContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Flexible(
          child: BaseCard(
            title: 'Scene Items',
            // trailingTitleWidget: VisibilityEditToggle(
            //   sceneItemType: SceneItemType.Source,
            //   tabletMode: true,
            // ),
            rightPadding: 12,
            paddingChild: EdgeInsets.all(0),
            child: SizedBox(
              height: 400.0,
              child: SceneItems(),
            ),
          ),
        ),
        Flexible(
          child: BaseCard(
            title: 'Audio',
            // trailingTitleWidget: VisibilityEditToggle(
            //   sceneItemType: SceneItemType.Audio,
            //   tabletMode: true,
            // ),
            leftPadding: 12,
            paddingChild: EdgeInsets.all(0),
            child: SizedBox(
              height: 400.0,
              child: AudioInputs(),
            ),
          ),
        ),
      ],
    );
  }
}
