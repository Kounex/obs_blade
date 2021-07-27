import 'package:flutter/material.dart';
import 'package:obs_blade/views/dashboard/widgets/scenes/scene_collection_control.dart';

import '../../../../shared/general/responsive_widget_wrapper.dart';
import 'exposed_controls/exposed_controls.dart';
import 'scene_buttons/scene_buttons.dart';
import 'scene_content/scene_content.dart';
import 'scene_content/scene_content_mobile.dart';
import 'scene_preview/scene_preview.dart';
import 'studio_mode_transition/studio_mode_transition.dart';

const double kSceneButtonSpace = 18.0;

class Scenes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExposedControls(),
        SizedBox(height: 24.0),
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: SceneCollectionControl(),
        ),
        SizedBox(height: 24.0),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(
                left: kSceneButtonSpace, right: kSceneButtonSpace),
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
          padding: const EdgeInsets.only(
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
