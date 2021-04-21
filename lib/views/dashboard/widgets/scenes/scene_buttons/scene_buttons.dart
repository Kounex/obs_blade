import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../../models/hidden_scene.dart';
import '../../../../../stores/shared/network.dart';
import '../../../../../stores/views/dashboard.dart';
import '../../../../../types/classes/api/scene.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../scenes.dart';
import 'scene_button.dart';

class SceneButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = context.read<DashboardStore>();
    NetworkStore networkStore = context.read<NetworkStore>();

    return LayoutBuilder(builder: (context, constraints) {
      double size = 100.0;
      double buttonSizeToFitThree =
          (constraints.maxWidth - 4 * kSceneButtonSpace) / 3;

      size = buttonSizeToFitThree < size ? buttonSizeToFitThree : size;

      return ValueListenableBuilder(
        valueListenable:
            Hive.box<HiddenScene>(HiveKeys.HiddenScene.name).listenable(),
        builder: (context, Box<HiddenScene> hiddenScenesBox, child) =>
            Observer(builder: (_) {
          Iterable<Scene>? visibleScenes = dashboardStore.scenes;
          List<HiddenScene> hiddenScenes = [];

          visibleScenes?.forEach(
            (scene) => hiddenScenes.addAll(
              hiddenScenesBox.values.where((hiddenSceneInBox) {
                bool isHiddenScene = hiddenSceneInBox.sceneName == scene.name;

                if (isHiddenScene) {
                  if (networkStore.activeSession!.connection.name != null &&
                      hiddenSceneInBox.connectionName != null) {
                    isHiddenScene =
                        networkStore.activeSession!.connection.name ==
                            hiddenSceneInBox.connectionName;
                  } else {
                    isHiddenScene = networkStore.activeSession!.connection.ip ==
                        hiddenSceneInBox.ipAddress;
                  }
                }

                return isHiddenScene;
              }),
            ),
          );

          if (!dashboardStore.editSceneVisibility) {
            visibleScenes = visibleScenes?.where((scene) => hiddenScenes
                .every((hiddenScene) => scene.name != hiddenScene.sceneName));
          }

          return Wrap(
            runSpacing: kSceneButtonSpace,
            spacing: kSceneButtonSpace,
            children: visibleScenes != null && visibleScenes.length > 0
                ? visibleScenes.map((scene) {
                    HiddenScene? hiddenScene;
                    try {
                      hiddenScene = hiddenScenes.firstWhere(
                          (element) => element.sceneName == scene.name);
                    } catch (e) {}

                    return SceneButton(
                      scene: scene,
                      height: size,
                      width: size,
                      visible: hiddenScene == null,
                      onVisibilityTap: () {
                        if (hiddenScene != null) {
                          hiddenScene!.delete();
                        } else {
                          hiddenScene = HiddenScene(
                            scene.name,
                            networkStore.activeSession!.connection.name,
                            networkStore.activeSession!.connection.ip,
                          );

                          Hive.box<HiddenScene>(HiveKeys.HiddenScene.name)
                              .add(hiddenScene!);
                        }
                      },
                    );
                  }).toList()
                : [Text('No Scenes available')],
          );
        }),
      );
    });
  }
}
