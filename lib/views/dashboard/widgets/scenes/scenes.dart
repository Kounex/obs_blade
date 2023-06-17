import 'package:flutter/material.dart';
import 'package:obs_blade/views/dashboard/widgets/scenes/hotkeys/hotkeys.dart';
import 'package:obs_blade/views/dashboard/widgets/scenes/profile_scene_collection/profile_scene_collection.dart';

import '../../../../shared/general/responsive_widget_wrapper.dart';
import 'exposed_controls/exposed_controls.dart';
import 'scene_buttons/scene_buttons.dart';
import 'scene_content/scene_content.dart';
import 'scene_content/scene_content_mobile.dart';
import 'scene_preview/scene_preview.dart';
import 'studio_mode_transition/studio_mode_transition.dart';

const double kSceneButtonSpace = 18.0;

class Scenes extends StatelessWidget {
  const Scenes({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ProfileSceneCollection(),
        ExposedControls(),
        Hotkeys(),
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
        Padding(
          padding: EdgeInsets.only(
            top: 24.0,
            left: 12.0,
            right: 12.0,
          ),
          child: StudioModeTransition(),
        ),
        SizedBox(height: 24.0),
        ScenePreview(),
        ResponsiveWidgetWrapper(
          mobileWidget: SceneContentMobile(),
          tabletWidget: SceneContent(),
        ),
      ],
    );
  }
}
