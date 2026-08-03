import 'package:flutter/material.dart';

import '../../../../../shared/design/design.dart';
import '../../../../../shared/general/base/card.dart';
import 'audio_inputs/audio_inputs.dart';
import 'scene_items/scene_items.dart';

class SceneContent extends StatelessWidget {
  /// When true, the Audio card is on the left.
  final bool audioFirst;

  const SceneContent({
    super.key,
    this.audioFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final Widget itemsCard = StaggeredEntrance(
      index: this.audioFirst ? 1 : 0,
      child: const BaseCard(
        title: 'Scene Items',
        rightPadding: 12,
        paddingChild: EdgeInsets.all(0),
        child: SizedBox(
          height: 400.0,
          child: SceneItems(),
        ),
      ),
    );

    final Widget audioCard = StaggeredEntrance(
      index: this.audioFirst ? 0 : 1,
      child: const BaseCard(
        title: 'Audio',
        leftPadding: 12,
        paddingChild: EdgeInsets.all(0),
        child: SizedBox(
          height: 400.0,
          child: AudioInputs(),
        ),
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Flexible(child: this.audioFirst ? audioCard : itemsCard),
        Flexible(child: this.audioFirst ? itemsCard : audioCard),
      ],
    );
  }
}
