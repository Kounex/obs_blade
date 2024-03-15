import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

import '../../../../../models/hidden_scene.dart';
import '../../../../../shared/general/hive_builder.dart';
import '../../../../../stores/shared/network.dart';
import '../../../../../stores/views/dashboard.dart';
import '../../../../../types/classes/api/scene.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../scenes.dart';
import 'scene_button.dart';

enum SceneButtonsMode {
  wrap,
  horizontalScroll,
}

class SceneButtons extends StatelessWidget {
  final double size;

  final SceneButtonsMode mode;

  const SceneButtons({
    super.key,
    this.size = 100,
    this.mode = SceneButtonsMode.wrap,
  });

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();
    NetworkStore networkStore = GetIt.instance<NetworkStore>();

    return LayoutBuilder(builder: (context, constraints) {
      double size = this.size;
      double buttonSizeToFitThree =
          (constraints.maxWidth - 4 * kSceneButtonSpace) / 3;

      size = buttonSizeToFitThree < size ? buttonSizeToFitThree : size;

      return HiveBuilder<HiddenScene>(
        hiveKey: HiveKeys.HiddenScene,
        builder: (context, hiddenScenesBox, child) =>
            Observer(builder: (context) {
          Iterable<Scene>? visibleScenes = dashboardStore.scenes;
          List<HiddenScene> hiddenScenes = [];

          if (networkStore.activeSession != null) {
            visibleScenes?.forEach(
              (scene) => hiddenScenes.addAll(
                hiddenScenesBox.values.where((hiddenSceneInBox) =>
                        hiddenSceneInBox.isScene(
                            scene.sceneName,
                            networkStore.activeSession?.connection.name,
                            networkStore.activeSession?.connection.host)
                    // {
                    //   bool isHiddenScene = hiddenSceneInBox.sceneName == scene.name;

                    //   if (isHiddenScene) {
                    //     if (networkStore.activeSession!.connection.name != null &&
                    //         hiddenSceneInBox.connectionName != null) {
                    //       isHiddenScene =
                    //           networkStore.activeSession!.connection.name ==
                    //               hiddenSceneInBox.connectionName;
                    //     } else {
                    //       isHiddenScene =
                    //           networkStore.activeSession!.connection.host ==
                    //               hiddenSceneInBox.host;
                    //     }
                    //   }

                    //   return isHiddenScene;
                    // }
                    ),
              ),
            );
          }

          if (!dashboardStore.editSceneVisibility) {
            visibleScenes = visibleScenes?.where((scene) => hiddenScenes.every(
                (hiddenScene) => scene.sceneName != hiddenScene.sceneName));
          }

          final List<Widget>? sceneButtons = visibleScenes?.map((scene) {
            HiddenScene? hiddenScene;
            try {
              hiddenScene = hiddenScenes.firstWhere(
                  (element) => element.sceneName == scene.sceneName);
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
                    scene.sceneName,
                    networkStore.activeSession!.connection.name,
                    networkStore.activeSession!.connection.host,
                  );

                  Hive.box<HiddenScene>(HiveKeys.HiddenScene.name)
                      .add(hiddenScene!);
                }
              },
            );
          }).toList();

          if (sceneButtons == null || sceneButtons.isEmpty) {
            return const Center(
              child: Text(
                'No Scenes available',
              ),
            );
          }

          return switch (this.mode) {
            SceneButtonsMode.wrap => Wrap(
                runSpacing: kSceneButtonSpace,
                spacing: kSceneButtonSpace,
                children: sceneButtons,
              ),
            SceneButtonsMode.horizontalScroll => SizedBox(
                height: this.size + 24.0,
                child: MediaQuery.removePadding(
                  removeBottom: true,
                  context: context,
                  child: Scrollbar(
                    scrollbarOrientation: ScrollbarOrientation.bottom,
                    thumbVisibility: true,
                    trackVisibility: true,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(12.0),
                      itemCount: sceneButtons.length,
                      itemBuilder: (context, index) => sceneButtons[index],
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12.0),
                    ),
                  ),
                ),
              ),
          };
        }),
      );
    });
  }
}
