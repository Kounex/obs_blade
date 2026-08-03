import 'package:flutter/material.dart';

import '../../../../../shared/design/design.dart';
import 'audio_inputs/audio_inputs.dart';
import 'scene_items/scene_items.dart';

class SceneContentMobile extends StatelessWidget {
  /// When true, the Audio tab is listed (and shown) before Scene Items.
  final bool audioFirst;

  const SceneContentMobile({
    super.key,
    this.audioFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    final List<Widget> tabs = this.audioFirst
        ? const [
            Tab(child: Text('Audio')),
            Tab(child: Text('Scene Items')),
          ]
        : const [
            Tab(child: Text('Scene Items')),
            Tab(child: Text('Audio')),
          ];

    final List<Widget> views = this.audioFirst
        ? const [
            AudioInputs(),
            SceneItems(),
          ]
        : const [
            SceneItems(),
            AudioInputs(),
          ];

    return DefaultTabController(
      length: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: theme.cupertinoOverrideTheme!.barBackgroundColor,
            child: TabBar(
              labelColor: theme.colorScheme.secondary,
              unselectedLabelColor: theme.textTheme.bodySmall!.color,
              labelStyle: theme.textTheme.titleSmall!
                  .copyWith(fontWeight: FontWeight.w600),
              unselectedLabelStyle: theme.textTheme.titleSmall,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  width: 3.0,
                  color: theme.colorScheme.secondary,
                ),
                insets:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              ),
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              tabs: tabs,
            ),
          ),

          /// Grown from 300 to 400 (the tablet card extent) so resting rows
          /// aren't clipped mid-glyph - taller content still scrolls inside
          /// via [NestedScrollManager]
          SizedBox(
            height: 400,
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: views,
            ),
          )
        ],
      ),
    );
  }
}
