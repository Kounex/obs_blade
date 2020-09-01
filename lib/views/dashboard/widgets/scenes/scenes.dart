import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:obs_blade/shared/general/responsive_widget_wrapper.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/types/enums/request_type.dart';
import 'package:obs_blade/utils/network_helper.dart';
import 'package:provider/provider.dart';

import '../../../../stores/views/dashboard.dart';
import '../../../../types/enums/hive_keys.dart';
import '../../../../types/enums/settings_keys.dart';
import '../../../../utils/styling_helper.dart';
import 'scene_button.dart';
import 'scene_content/scene_content.dart';
import 'scene_content/scene_content_mobile.dart';

const double kSceneButtonSpace = 18.0;

class Scenes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = Provider.of<DashboardStore>(context);

    return Padding(
      padding: const EdgeInsets.only(top: 42.0),
      child: Column(
        children: [
          Center(
            child: Observer(
              builder: (_) => Padding(
                padding: const EdgeInsets.only(
                    left: kSceneButtonSpace, right: kSceneButtonSpace),
                child: Wrap(
                  runSpacing: kSceneButtonSpace,
                  spacing: kSceneButtonSpace,
                  children: dashboardStore.scenes != null &&
                          dashboardStore.scenes.length > 0
                      ? dashboardStore.scenes
                          .map((scene) => SceneButton(scene: scene))
                          .toList()
                      : [Text('No Scenes available')],
                ),
              ),
            ),
          ),
          // RaisedButton(
          //   onPressed: () => NetworkHelper.makeRequest(
          //       context.read<NetworkStore>().activeSession.socket,
          //       RequestType.PlayPauseMedia,
          //       {'sourceName': 'was geht ab', 'playPause': false}),
          //   child: Text('SOUND'),
          // ),
          ResponsiveWidgetWrapper(
            mobileWidget: SceneContentMobile(),
            tabletWidget: SceneContent(),
          ),
        ],
      ),
    );
  }
}
