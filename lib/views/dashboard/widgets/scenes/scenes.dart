import 'package:flutter/material.dart';
import 'package:obs_blade/views/dashboard/widgets/scenes/profile_scene_collection/profile_scene_collection.dart';
import 'package:obs_blade/views/dashboard/widgets/scenes/studio_mode_checkbox.dart';
import 'package:obs_blade/views/dashboard/widgets/scenes/studio_mode_transition_button.dart';
import 'package:obs_blade/views/dashboard/widgets/scenes/transition_controls.dart';

import '../../../../shared/general/responsive_widget_wrapper.dart';
import 'exposed_controls/exposed_controls.dart';
import 'scene_buttons/scene_buttons.dart';
import 'scene_content/scene_content.dart';
import 'scene_content/scene_content_mobile.dart';
import 'scene_preview/scene_preview.dart';

const double kSceneButtonSpace = 18.0;

class Scenes extends StatelessWidget {
  const Scenes({Key? key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ProfileSceneCollection(),
        ExposedControls(),
        SizedBox(height: 24.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            StudioModeCheckbox(),
            SizedBox(width: 24.0),
          ],
        ),
        Center(
          child: Padding(
            padding: EdgeInsets.only(
              top: 32.0,
              left: kSceneButtonSpace,
              right: kSceneButtonSpace,
            ),
            child: SceneButtons(),
          ),
        ),
        // BaseButton(
        //   onPressed: () => NetworkHelper.makeRequest(
        //       GetIt.instance<NetworkStore>().activeSession.socket,
        //       RequestType.PlayPauseMedia,
        //       {'sourceName': 'was geht ab', 'playPause': false}),
        //   text: 'SOUND',
        // ),
        SizedBox(height: 24.0),
        StudioModeTransitionButton(),
        SizedBox(height: 24.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TransitionControls(),
            SizedBox(width: 24.0),
          ],
        ),
        SizedBox(height: 24.0),
        ScenePreview(),
        SizedBox(height: 24.0),
        ResponsiveWidgetWrapper(
          mobileWidget: SceneContentMobile(),
          tabletWidget: SceneContent(),
        ),
      ],
    );
  }
}
