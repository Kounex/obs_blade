import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:obs_station/views/dashboard/widgets/scenes/scene_content.dart';
import 'package:provider/provider.dart';

import '../../../../stores/views/dashboard.dart';
import '../../../../types/enums/request_type.dart';
import '../../../../utils/network_helper.dart';

class Scenes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = Provider.of<DashboardStore>(context);

    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
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
                        .map(
                          (scene) => GestureDetector(
                            onTap: () => NetworkHelper.makeRequest(
                                dashboardStore.activeSession.socket.sink,
                                RequestType.SetCurrentScene,
                                {'scene-name': scene.name}),
                            child: Stack(
                              children: [
                                AnimatedContainer(
                                  duration: Duration(
                                      milliseconds: dashboardStore
                                                      .sceneTransitionDurationMS !=
                                                  null &&
                                              dashboardStore
                                                      .sceneTransitionDurationMS >=
                                                  0
                                          ? dashboardStore
                                              .sceneTransitionDurationMS
                                          : 0),
                                  alignment: Alignment.center,
                                  height: 100.0,
                                  width: 100.0,
                                  decoration: BoxDecoration(
                                    color: dashboardStore.activeSceneName ==
                                            scene.name
                                        ? Theme.of(context).accentColor
                                        : Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Text(
                                      scene.name,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: Duration(milliseconds: 50),
                                  height: 100.0,
                                  width: 100.0,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: dashboardStore.activeSceneName ==
                                              scene.name
                                          ? Theme.of(context).accentColor
                                          : Theme.of(context).cardColor,
                                    ),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList()
                    : [Text('No Scenes available')],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 42.0),
            child: SceneContent(),
          ),
        ],
      ),
    );
  }
}
