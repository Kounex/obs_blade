import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../../../shared/design/design.dart';
import '../../../../../shared/general/base/icon_button.dart';
import '../../../../../stores/views/canvas_view.dart';
import '../../../../../types/classes/api/scene_item.dart';
import '../scene_content/animated_toggle_icon.dart';
import '../scene_content/placeholder_scene_item.dart';

/// Items of the scene picked on another canvas: visibility + lock, the two
/// toggles that work by scene UUID. Groups show as one row (their children
/// aren't expanded in this view).
class CanvasSceneItems extends StatelessWidget {
  final CanvasViewStore canvasStore;
  final ScrollController controller;

  const CanvasSceneItems({
    super.key,
    required this.canvasStore,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        final items = this.canvasStore.sceneItems;
        final sceneName = this.canvasStore.selectedScene?.name;

        return ListView(
          controller: this.controller,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(top: AppSpacing.md),
          children: [
            if (sceneName != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  '$sceneName · ${this.canvasStore.viewedCanvas?.name ?? ''}'
                  ' canvas',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (items.isEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              const PlaceholderSceneItem(text: 'No Scene Items available...'),
            ] else
              ...items.indexed.map(
                (entry) => StaggeredEntrance(
                  key: ValueKey((
                    this.canvasStore.selectedSceneUuid,
                    entry.$2.sceneItemId,
                  )),
                  index: entry.$1,
                  rise: 0.0,
                  child: StaleGuard(
                    child: _CanvasSceneItemTile(
                      canvasStore: this.canvasStore,
                      sceneItem: entry.$2,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CanvasSceneItemTile extends StatelessWidget {
  final CanvasViewStore canvasStore;
  final SceneItem sceneItem;

  const _CanvasSceneItemTile({
    required this.canvasStore,
    required this.sceneItem,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String name = this.sceneItem.sourceName ?? '';
    final bool enabled = this.sceneItem.sceneItemEnabled ?? false;
    final bool? locked = this.sceneItem.sceneItemLocked;
    final bool isGroup = this.sceneItem.isGroup ?? false;

    return ListTile(
      dense: true,
      leading: Icon(
        isGroup
            ? CupertinoIcons.folder_solid
            : CupertinoIcons.photo_on_rectangle,
      ),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            toggled: enabled,
            label: enabled ? 'Hide $name' : 'Show $name',
            excludeSemantics: true,
            child: Pressable(
              haptic: true,
              onTap: () =>
                  this.canvasStore.setItemEnabled(this.sceneItem, !enabled),
              child: SizedBox(
                width: kBaseIconButtonMinHitArea,
                height: kBaseIconButtonMinHitArea,
                child: Center(
                  child: AnimatedToggleIcon(
                    icon: enabled ? Icons.visibility : Icons.visibility_off,
                    color: enabled
                        ? theme.colorScheme.secondary
                        : theme.disabledColor,
                  ),
                ),
              ),
            ),
          ),
          if (!isGroup && locked != null)
            Semantics(
              button: true,
              label: locked ? 'Unlock $name' : 'Lock $name',
              excludeSemantics: true,
              child: Pressable(
                haptic: true,
                onTap: () =>
                    this.canvasStore.setItemLocked(this.sceneItem, !locked),
                child: SizedBox(
                  width: kBaseIconButtonMinHitArea,
                  height: kBaseIconButtonMinHitArea,
                  child: Center(
                    child: AnimatedToggleIcon(
                      icon: locked
                          ? CupertinoIcons.lock_fill
                          : CupertinoIcons.lock_open,
                      color: locked
                          ? theme.colorScheme.onSurface
                          : theme.disabledColor,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
