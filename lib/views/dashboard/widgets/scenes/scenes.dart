import 'package:flutter/material.dart';

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
        SizedBox(height: 24.0),
        ExposedControls(),
        SizedBox(height: 24.0),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(
                left: kSceneButtonSpace, right: kSceneButtonSpace),
            child: SceneButtons(),
          ),
        ),
        // RaisedButton(
        //   onPressed: () => NetworkHelper.makeRequest(
        //       context.read<NetworkStore>().activeSession.socket,
        //       RequestType.PlayPauseMedia,
        //       {'sourceName': 'was geht ab', 'playPause': false}),
        //   child: Text('SOUND'),
        // ),
        Padding(
          padding: const EdgeInsets.only(top: 32.0, right: 12.0),
          child: StudioModeTransition(),
        ),

        Padding(
          padding: const EdgeInsets.only(top: 24.0),
          child: ScenePreview(),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 24.0),
          child: ResponsiveWidgetWrapper(
            mobileWidget: SceneContentMobile(),
            tabletWidget: SceneContent(),
          ),
        ),
      ],
    );
  }
}
