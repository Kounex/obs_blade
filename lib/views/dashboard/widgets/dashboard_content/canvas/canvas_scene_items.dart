import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../../../shared/design/design.dart';
import '../../../../../shared/general/base/icon_button.dart';
import '../../../../../stores/views/canvas_view.dart';
import '../../../../../types/classes/api/scene_item.dart';
import '../scene_content/animated_toggle_icon.dart';
import '../scene_content/placeholder_scene_item.dart';
import '../scene_content/visibility_slide_wrapper.dart';

/// Items of the scene picked on another canvas: visibility + lock. Groups
/// expand like the main scene items (tap the row) - their children toggle
/// in the group's own scene. Edit Scene Visibility hides rows like it does
/// for the main items.
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
        /// A group's children only while it's expanded
        final items = this.canvasStore.sceneItems
            .where(
              (item) =>
                  item.parentGroupName == null ||
                  this.canvasStore.expandedGroups.contains(
                    item.parentGroupName,
                  ),
            )
            .toList();
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
                    entry.$2.parentGroupName,
                    entry.$2.sceneItemId,
                  )),
                  index: entry.$1,
                  rise: 0.0,
                  child: StaleGuard(
                    /// Edit Scene Visibility hides / shows the row in the
                    /// app, stored per canvas
                    child: VisibilitySlideWrapper(
                      sceneItem: entry.$2,
                      sceneName: sceneName,
                      canvasName: this.canvasStore.viewedCanvas?.name,
                      child: _CanvasSceneItemTile(
                        canvasStore: this.canvasStore,
                        sceneItem: entry.$2,
                      ),
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
    final bool expanded =
        isGroup && this.canvasStore.expandedGroups.contains(name);
    final IconData typeIcon = isGroup
        ? expanded
              ? CupertinoIcons.folder
              : CupertinoIcons.folder_solid
        : CupertinoIcons.photo_on_rectangle;

    final Widget tile = ListTile(
      dense: true,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (this.sceneItem.parentGroupName != null) ...[
            const SizedBox(width: 4.0),
            Icon(
              Icons.subdirectory_arrow_right_sharp,
              size: 18.0,
              color: theme.textTheme.bodySmall!.color,
            ),
            const SizedBox(width: 16.0),
          ],
          AnimatedSwitcher(
            duration: AppMotion.fast,
            switchInCurve: AppMotion.standard,
            switchOutCurve: AppMotion.exit,
            child: Icon(typeIcon, key: ValueKey(typeIcon)),
          ),
        ],
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
                        ? theme.colorScheme.onSurface
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

    if (!isGroup) return tile;

    /// The whole group row toggles its children, like the main items
    return Semantics(
      button: true,
      expanded: expanded,
      label: expanded ? 'Collapse group $name' : 'Expand group $name',
      child: Pressable(
        onTap: () => this.canvasStore.toggleGroup(this.sceneItem),
        child: tile,
      ),
    );
  }
}
