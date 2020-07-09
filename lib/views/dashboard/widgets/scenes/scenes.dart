import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:obs_station/models/settings.dart';
import 'package:obs_station/types/enums/hive_keys.dart';
import 'package:obs_station/utils/styling_helper.dart';
import 'package:obs_station/views/dashboard/widgets/scenes/scene_button.dart';
import 'package:obs_station/views/dashboard/widgets/scenes/scene_content/scene_content_mobile.dart';
import 'package:provider/provider.dart';

import '../../../../stores/views/dashboard.dart';
import 'scene_content/scene_content.dart';

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
              builder: (_) => Wrap(
                runSpacing: 24.0,
                spacing: 24.0,
                children: dashboardStore.scenes != null &&
                        dashboardStore.scenes.length > 0
                    ? dashboardStore.scenes
                        .map((scene) => SceneButton(scene: scene))
                        .toList()
                    : [Text('No Scenes available')],
              ),
            ),
          ),
          ValueListenableBuilder(
            valueListenable:
                Hive.box<Settings>(HiveKeys.Settings.name).listenable(),
            builder: (context, Box<Settings> settingsBox, child) => Padding(
              padding: const EdgeInsets.only(top: 42.0),
              child: MediaQuery.of(context).size.width >
                          StylingHelper.MAX_WIDTH_MOBILE ||
                      settingsBox.get(0).enforceTabletMode
                  ? SceneContent()
                  : SceneContentMobile(),
            ),
          ),
        ],
      ),
    );
  }
}
