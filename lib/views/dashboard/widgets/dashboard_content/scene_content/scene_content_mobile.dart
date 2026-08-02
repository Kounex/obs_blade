import 'package:flutter/material.dart';

import '../../../../../shared/design/design.dart';
import 'audio_inputs/audio_inputs.dart';
import 'scene_items/scene_items.dart';

class SceneContentMobile extends StatelessWidget {
  const SceneContentMobile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return DefaultTabController(
      // length: 3,
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
              tabs: const [
                Tab(
                  child: Text('Scene Items'),
                ),
                Tab(
                  child: Text('Audio'),
                ),
                // Tab(
                //   child: Text('Media'),
                // ),
              ],
            ),
          ),
          /// Grown from 300 to 400 (the tablet card extent) so resting rows
          /// aren't clipped mid-glyph - taller content still scrolls inside
          /// via [NestedScrollManager]
          const SizedBox(
            height: 400,
            child: TabBarView(
              physics: NeverScrollableScrollPhysics(),
              children: [
                SceneItems(),
                AudioInputs(),
                // MediaInputs(),
              ],
            ),
          )
        ],
      ),
    );
  }
}
