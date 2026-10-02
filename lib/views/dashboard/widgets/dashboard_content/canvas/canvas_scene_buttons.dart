import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../../../shared/animator/selectable_box.dart';
import '../../../../../shared/design/design.dart';
import '../../../../../shared/overlay/base_progress_indicator.dart';
import '../../../../../stores/views/canvas_view.dart';
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

    return Observer(
      builder: (context) {
        if (this.canvasStore.loadingScenes && this.canvasStore.scenes.isEmpty) {
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
        final List<Widget> buttons = this.canvasStore.scenes.indexed.map((
          entry,
        ) {
          final scene = entry.$2;
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
                  if (selected) live ? 'live' : 'shown',
                ].join(', '),
                hint: live
                    ? 'Switches the $canvasName canvas to this scene live'
                    : 'Shows this scene of the $canvasName canvas in the app '
                          '- the live scene is set in OBS',
                excludeSemantics: true,
                child: Pressable(
                  haptic: true,
                  onTap: () {
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
                  child: SelectableBox(
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
                ),
              ),
            ),
          );
        }).toList();

        return sceneButtonsLayout(this.mode, this.size, buttons);
      },
    );
  }
}
