import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';

import '../../../../../models/hidden_scene.dart';
import '../../../../../shared/animator/selectable_box.dart';
import '../../../../../shared/design/design.dart';
import '../../../../../shared/general/hive_builder.dart';
import '../../../../../shared/overlay/base_progress_indicator.dart';
import '../../../../../stores/shared/network.dart';
import '../../../../../stores/views/canvas_view.dart';
import '../../../../../stores/views/dashboard.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/classes/api/obs_canvas.dart';
import '../scene_buttons/scene_button.dart' show SceneVisibilityBadge;
import '../scene_buttons/scene_buttons.dart';
import 'canvas_output_controls.dart';

/// Scene buttons of a non-main canvas.
///
/// With live control (Aitum Vertical, see
/// [CanvasViewStore.canControlViewedCanvas]) they work like the program
/// scene buttons: a tap switches the canvas' live scene, the live one wears
/// the program tally and is the one the dashboard shows.
///
/// Without it a tap only picks the scene the dashboard shows (preview +
/// items) - core OBS has no live scene for non-main canvases. That pick uses
/// the accent ring, never the program tally, so it can't read as "live", and
/// the first tap explains what switching the live scene would need.
///
/// Edit Scene Visibility works here too: a tap then hides / shows the scene
/// in the app, stored per canvas ([HiddenScene.canvasName]) so a same-named
/// main scene stays untouched.
class CanvasSceneButtons extends StatelessWidget {
  final CanvasViewStore canvasStore;
  final double size;
  final SceneButtonsMode mode;

  const CanvasSceneButtons({
    super.key,
    required this.canvasStore,
    required this.size,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStatusColors statusColors = theme.extension<AppStatusColors>()!;

    final DashboardStore dashboardStore = GetIt.instance<DashboardStore>();
    final NetworkStore networkStore = GetIt.instance<NetworkStore>();

    return HiveBuilder<HiddenScene>(
      hiveKey: HiveKeys.HiddenScene,
      builder: (context, hiddenScenesBox, child) => Observer(
        builder: (context) {
          if (this.canvasStore.loadingScenes &&
              this.canvasStore.scenes.isEmpty) {
            return Center(
              child: BaseProgressIndicator(text: 'Fetching scenes...'),
            );
          }
          if (this.canvasStore.scenes.isEmpty) {
            return const SceneButtonsPlaceholder(
              text: 'No Scenes in this canvas',
            );
          }

          final String canvasName = this.canvasStore.viewedCanvas?.name ?? '';
          final bool live = this.canvasStore.canControlViewedCanvas;
          final bool editing = dashboardStore.editSceneVisibility;
          final connection = networkStore.activeSession?.connection;

          HiddenScene? hiddenEntry(CanvasScene scene) => connection == null
              ? null
              : hiddenScenesBox.values
                    .where(
                      (hidden) => hidden.isScene(
                        scene.name,
                        connection.name,
                        connection.host,
                        canvasName: canvasName,
                      ),
                    )
                    .firstOrNull;

          void toggleHidden(CanvasScene scene) {
            if (connection == null) return;
            final hidden = hiddenEntry(scene);
            if (hidden != null) {
              hidden.delete();
            } else {
              Hive.box<HiddenScene>(HiveKeys.HiddenScene.name).add(
                HiddenScene(
                  scene.name,
                  connection.name,
                  connection.host,
                  canvasName,
                ),
              );
            }
          }

          final visibleScenes = editing
              ? this.canvasStore.scenes
              : this.canvasStore.scenes.where(
                  (scene) => hiddenEntry(scene) == null,
                );
          if (visibleScenes.isEmpty) {
            return const SceneButtonsPlaceholder(text: 'No Scenes available');
          }

          final List<Widget> buttons = visibleScenes.indexed.map((entry) {
            final scene = entry.$2;
            final bool shown = hiddenEntry(scene) == null;
            final bool selected = live
                ? scene.name == this.canvasStore.aitumLiveSceneName
                : scene.uuid == this.canvasStore.selectedSceneUuid;
            final Color ringColor = live
                ? statusColors.program
                : theme.colorScheme.secondary;

            return StaggeredEntrance(
              key: ValueKey(scene.uuid),
              index: entry.$1,
              scaleFrom: 0.985,
              child: StaleGuard(
                child: Semantics(
                  button: true,
                  selected: selected,
                  label: [
                    scene.name,
                    if (editing)
                      shown ? 'shown' : 'hidden'
                    else if (selected)
                      live ? 'live' : 'shown',
                  ].join(', '),
                  hint: editing
                      ? 'Toggles whether this scene is shown in the app'
                      : live
                      ? 'Switches the $canvasName canvas to this scene live'
                      : 'Shows this scene of the $canvasName canvas in the app '
                            '- the live scene is set in OBS',
                  excludeSemantics: true,
                  child: Pressable(
                    haptic: true,
                    onTap: () {
                      /// Editing visibility: a tap must never switch live
                      if (editing) {
                        toggleHidden(scene);
                        return;
                      }
                      if (live) {
                        this.canvasStore.switchLiveScene(scene);
                        return;
                      }
                      this.canvasStore.selectScene(scene.uuid);
                      if (!this.canvasStore.viewOnlyHintShown) {
                        this.canvasStore.viewOnlyHintShown = true;
                        showCanvasLiveControlHint(
                          context,
                          this.canvasStore,
                          prefix: 'Shown in the app only',
                        );
                      }
                    },
                    child: Stack(
                      children: [
                        SelectableBox(
                          selected: selected,
                          selectedStateBoxBorder: selected,
                          colorSelected: Color.alphaBlend(
                            ringColor.withValues(alpha: 0.10),
                            theme.cardColor,
                          ),
                          colorSelectedBorder: ringColor,
                          colorUnselected: theme.cardColor,
                          height: this.size,
                          width: this.size,
                          text: scene.name,
                        ),
                        Positioned(
                          top: 6.0,
                          right: 6.0,
                          child: AnimatedSwitcher(
                            duration: AppMotion.medium,
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  ),
                                ),
                            child: editing
                                ? SceneVisibilityBadge(
                                    key: const ValueKey('visibility-badge'),
                                    visible: shown,
                                  )
                                : const SizedBox(key: ValueKey('no-badge')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList();

          return sceneButtonsLayout(this.mode, this.size, buttons);
        },
      ),
    );
  }
}
