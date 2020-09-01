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
            noPaddingChild: true,
            child: SizedBox(
              height: 350.0,
              child: SceneItems(),
            ),
          ),
        ),
        Expanded(
          child: BaseCard(
            title: 'Audio',
            noPaddingChild: true,
            child: SizedBox(
              height: 350.0,
              child: AudioInputs(),
            ),
          ),
        ),
      ],
    );
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                color: Theme.of(context).cardColor,
                height: 30.0,
                alignment: Alignment.center,
                child: Text('Sources'),
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).cardColor,
                height: 30.0,
                alignment: Alignment.center,
                child: Text('Audio'),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(height: 250.0, child: SceneItems()),
              ),
            ),
            VerticalDivider(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(height: 250.0, child: AudioInputs()),
              ),
            )
          ],
        ),
      ],
    );
  }
}
