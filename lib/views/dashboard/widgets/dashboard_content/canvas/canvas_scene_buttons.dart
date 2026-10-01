import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../../../shared/animator/selectable_box.dart';
import '../../../../../shared/design/design.dart';
import '../../../../../shared/overlay/base_progress_indicator.dart';
import '../../../../../stores/views/canvas_view.dart';
import '../scene_buttons/scene_buttons.dart';

/// Scene buttons of a non-main canvas. A tap picks the scene the dashboard
/// shows (preview + items) - it does not change the canvas' live scene,
/// which core OBS doesn't expose for non-main canvases. The pick uses the
/// accent ring, never the red program tally, so it can't read as "live".
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
        final List<Widget> buttons = this.canvasStore.scenes.indexed.map((
          entry,
        ) {
          final scene = entry.$2;
          final bool selected =
              scene.uuid == this.canvasStore.selectedSceneUuid;

          return StaggeredEntrance(
            key: ValueKey(scene.uuid),
            index: entry.$1,
            scaleFrom: 0.985,
            child: StaleGuard(
              child: Semantics(
                button: true,
                selected: selected,
                label: [scene.name, if (selected) 'shown'].join(', '),
                hint:
                    'Shows this scene of the $canvasName canvas in the app - '
                    'the live scene is set in OBS',
                excludeSemantics: true,
                child: Pressable(
                  haptic: true,
                  onTap: () => this.canvasStore.selectScene(scene.uuid),
                  child: SelectableBox(
                    selected: selected,
                    selectedStateBoxBorder: selected,
                    colorSelected: Color.alphaBlend(
                      theme.colorScheme.secondary.withValues(alpha: 0.10),
                      theme.cardColor,
                    ),
                    colorSelectedBorder: theme.colorScheme.secondary,
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
