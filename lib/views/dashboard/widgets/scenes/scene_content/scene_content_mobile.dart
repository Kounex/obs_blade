import 'package:flutter/material.dart';
import 'package:obs_blade/views/dashboard/widgets/scenes/scene_content/media_inputs/media_inputs.dart';

import 'audio_inputs/audio_inputs.dart';
import 'scene_items/scene_items.dart';

class SceneContentMobile extends StatelessWidget {
  const SceneContentMobile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      // length: 3,
      length: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Theme.of(context).cupertinoOverrideTheme!.barBackgroundColor,
            child: const TabBar(
              tabs: [
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
          const SizedBox(
            height: 300,
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
