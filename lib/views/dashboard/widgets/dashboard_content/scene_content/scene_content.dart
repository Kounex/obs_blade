import 'package:flutter/material.dart';

import '../../../../../shared/design/design.dart';
import '../dashboard_element_card.dart';
import 'audio_inputs/audio_inputs.dart';
import 'scene_items/scene_items.dart';

class SceneContent extends StatelessWidget {
  /// When true, the Audio card is on the left.
  final bool audioFirst;

  const SceneContent({super.key, this.audioFirst = false});

  @override
  Widget build(BuildContext context) {
    /// 12px outer side margins + a 12px gutter (6px per card side) - the
    /// tablet rendering of the dashboard's content-card grid
    final Widget itemsCard = StaggeredEntrance(
      index: this.audioFirst ? 1 : 0,
      scaleFrom: 0.985,
      child: const DashboardElementCard(
        title: 'Scene Items',
        margin: EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.md / 2),
        child: SizedBox(height: 400.0, child: SceneItems()),
      ),
    );

    final Widget audioCard = StaggeredEntrance(
      index: this.audioFirst ? 0 : 1,
      scaleFrom: 0.985,
      child: const DashboardElementCard(
        title: 'Audio',
        margin: EdgeInsets.only(left: AppSpacing.md / 2, right: AppSpacing.md),
        child: SizedBox(height: 400.0, child: AudioInputs()),
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
