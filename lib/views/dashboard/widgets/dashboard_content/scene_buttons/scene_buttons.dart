import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/shared/design/design.dart';

import '../../../../../models/hidden_scene.dart';
import '../../../../../shared/general/hive_builder.dart';
import '../../../../../stores/shared/network.dart';
import '../../../../../stores/views/canvas_view.dart';
import '../../../../../stores/views/dashboard.dart';
import '../../../../../types/classes/api/scene.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../canvas/canvas_scene_buttons.dart';
import 'scene_button.dart';

enum SceneButtonsMode { wrap, horizontalScroll }

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

    return LayoutBuilder(
      builder: (context, constraints) {
        double size = this.size;
        double buttonSizeToFitThree =
            (constraints.maxWidth - 4 * AppSpacing.lg) / 3;

        size = buttonSizeToFitThree < size ? buttonSizeToFitThree : size;

        return HiveBuilder<HiddenScene>(
          hiveKey: HiveKeys.HiddenScene,
          builder: (context, hiddenScenesBox, child) => Observer(
            builder: (context) {
              /// Another OBS canvas is viewed: its scenes instead (picked
              /// for viewing, no live switch - see [CanvasViewStore])
              final CanvasViewStore? canvasStore = canvasViewStoreOrNull();
              if (canvasStore != null && canvasStore.isViewingOtherCanvas) {
                return CanvasSceneButtons(
                  canvasStore: canvasStore,
                  size: size,
                  mode: this.mode,
                );
              }

              Iterable<Scene>? visibleScenes = dashboardStore.scenes;
              List<HiddenScene> hiddenScenes = [];

              if (networkStore.activeSession != null) {
                visibleScenes?.forEach(
                  (scene) => hiddenScenes.addAll(
                    hiddenScenesBox.values.where(
                      (hiddenSceneInBox) => hiddenSceneInBox.isScene(
                        scene.sceneName,
                        networkStore.activeSession?.connection.name,
                        networkStore.activeSession?.connection.host,
                      ),
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
                visibleScenes = visibleScenes?.where(
                  (scene) => hiddenScenes.every(
                    (hiddenScene) => scene.sceneName != hiddenScene.sceneName,
                  ),
                );
              }

              final List<Widget>? sceneButtons = visibleScenes?.indexed.map((
                entry,
              ) {
                final int index = entry.$1;
                final Scene scene = entry.$2;

                HiddenScene? hiddenScene;
                try {
                  hiddenScene = hiddenScenes.firstWhere(
                    (element) => element.sceneName == scene.sceneName,
                  );
                } catch (e) {}

                return StaggeredEntrance(
                  index: index,
                  scaleFrom: 0.985,
                  child: SceneButton(
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

                        Hive.box<HiddenScene>(
                          HiveKeys.HiddenScene.name,
                        ).add(hiddenScene!);
                      }
                    },
                  ),
                );
              }).toList();

              if (sceneButtons == null || sceneButtons.isEmpty) {
                return const SceneButtonsPlaceholder(
                  text: 'No Scenes available',
                );
              }

              return sceneButtonsLayout(this.mode, this.size, sceneButtons);
            },
          ),
        );
      },
    );
  }
}

/// Wrap / horizontal-scroll arrangement shared by the program scene buttons
/// and the ones of another canvas ([CanvasSceneButtons])
Widget sceneButtonsLayout(
  SceneButtonsMode mode,
  double rowSize,
  List<Widget> sceneButtons,
) => switch (mode) {
  SceneButtonsMode.wrap => Wrap(
    runSpacing: AppSpacing.lg,
    spacing: AppSpacing.lg,
    children: sceneButtons,
  ),
  SceneButtonsMode.horizontalScroll => Builder(
    builder: (context) => SizedBox(
      height: rowSize + 24.0,
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
            separatorBuilder: (context, index) => const SizedBox(width: 12.0),
          ),
        ),
      ),
    ),
  ),
};

/// Empty state of the scene buttons area
class SceneButtonsPlaceholder extends StatelessWidget {
  final String text;

  const SceneButtonsPlaceholder({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final AppTextColors textColors = Theme.of(
      context,
    ).extension<AppTextColors>()!;
    return StaggeredEntrance(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.photo_on_rectangle,
              size: 28.0,
              color: textColors.textOrnament,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              this.text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall!.copyWith(color: textColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
