import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_content/scene_items/filter_list/filter_list.dart';

import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/general/base/icon_button.dart';
import '../../../../../../shared/general/hive_builder.dart';
import '../../../../../../stores/views/dashboard.dart';
import '../../../../../../types/classes/api/scene_item.dart';
import '../../../../../../types/enums/hive_keys.dart';
import '../../../../../../types/enums/request_type.dart';
import '../../../../../../types/enums/settings_keys.dart';
import '../animated_toggle_icon.dart';
import 'media_controls.dart';
import 'text_source_sheet.dart';

class SceneItemTile extends StatelessWidget {
  final SceneItem sceneItem;

  const SceneItemTile({super.key, required this.sceneItem});

  /// Groups in WebSocket 5.X and higher is weird, therefore we need to use
  /// the parents scene item name as the 'sceneName' property if we are
  /// changing a child of a group...
  String? _sceneName(DashboardStore dashboardStore, Box settingsBox) =>
      this.sceneItem.parentGroupName ??
      (settingsBox.get(
                SettingsKeys.ExposeStudioControls.name,
                defaultValue: false,
              ) &&
              dashboardStore.studioMode
          ? dashboardStore.studioModePreviewSceneName
          : dashboardStore.activeSceneName);

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();
    ThemeData theme = Theme.of(context);

    bool isGroup = this.sceneItem.isGroup ?? false;

    IconData typeIcon = isGroup
        ? this.sceneItem.displayGroup
              ? CupertinoIcons.folder
              : CupertinoIcons.folder_solid
        : CupertinoIcons.photo_on_rectangle;

    /// The Media hub owns media transport while it is exposed - rows then
    /// keep the lock like every other source. Hub off → the row transport
    /// stays, so media control never disappears with the toggle
    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [SettingsKeys.ExposeMediaHub],
      builder: (context, settingsBox, child) => _row(
        context,
        dashboardStore: dashboardStore,
        theme: theme,
        isGroup: isGroup,
        typeIcon: typeIcon,
        rowMediaControls:
            !isGroup &&
            isMediaInputKind(this.sceneItem.inputKind) &&
            !(settingsBox.get(
                  SettingsKeys.ExposeMediaHub.name,
                  defaultValue: true,
                )
                as bool),
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required DashboardStore dashboardStore,
    required ThemeData theme,
    required bool isGroup,
    required IconData typeIcon,
    required bool rowMediaControls,
  }) {
    /// Source color assigned in OBS 32+ (Sources dock -> Set Color) tints
    /// the full row, OBS-style. The key resolves like the mutations do
    /// ([_sceneName]): children are cached under their parent group's
    /// source name. No color -> exactly the previous rendering. The
    /// Container sits inside the VisibilitySlideWrapper's Slidable, so
    /// the tint travels with the row and the slide actions stay behind
    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [SettingsKeys.ExposeStudioControls],
      builder: (context, settingsBox, child) => Observer(
        builder: (context) {
          final Color? tint = dashboardStore
              .sceneItemColors['${this._sceneName(dashboardStore, settingsBox)}|${this.sceneItem.sceneItemId}'];
          return Container(
            color: tint,
            child: Pressable(
              /// Group rows forward the tap of the whole row to the same
              /// group visibility toggle the leading icon already exposes
              /// (still gated on the visibility edit mode)
              onTap:
                  isGroup &&
                      !dashboardStore.editAudioVisibility &&
                      !dashboardStore.editSceneItemVisibility
                  ? () => dashboardStore.toggleSceneItemGroupVisibility(
                      this.sceneItem,
                    )
                  : null,
              child: ListTile(
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
                    GestureDetector(
                      onTap: () =>
                          (!dashboardStore.editAudioVisibility &&
                              !dashboardStore.editSceneItemVisibility)
                          ? dashboardStore.toggleSceneItemGroupVisibility(
                              this.sceneItem,
                            )
                          : null,
                      child: AnimatedSwitcher(
                        duration: AppMotion.fast,
                        switchInCurve: AppMotion.standard,
                        switchOutCurve: AppMotion.exit,
                        child: Icon(typeIcon, key: ValueKey(typeIcon)),
                      ),
                    ),
                  ],
                ),
                title: Text(
                  this.sceneItem.sourceName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HiveBuilder<dynamic>(
                      hiveKey: HiveKeys.Settings,
                      rebuildKeys: const [SettingsKeys.ExposeStudioControls],
                      builder: (context, settingsBox, child) => Semantics(
                        button: true,
                        toggled: this.sceneItem.sceneItemEnabled,
                        label: this.sceneItem.sceneItemEnabled!
                            ? 'Hide ${this.sceneItem.sourceName}'
                            : 'Show ${this.sceneItem.sourceName}',
                        excludeSemantics: true,
                        child: Pressable(
                          haptic: true,
                          onTap: () => dashboardStore.sendMutation(
                            RequestType.SetSceneItemEnabled,
                            fields: {
                              'sceneName': this._sceneName(
                                dashboardStore,
                                settingsBox,
                              ),
                              'sceneItemId': this.sceneItem.sceneItemId,
                              'sceneItemEnabled':
                                  !this.sceneItem.sceneItemEnabled!,
                            },
                            label: 'Source visibility',
                          ),
                          child: SizedBox(
                            width: kBaseIconButtonMinHitArea,
                            height: kBaseIconButtonMinHitArea,
                            child: Center(
                              child: AnimatedToggleIcon(
                                icon: this.sceneItem.sceneItemEnabled!
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: this.sceneItem.sceneItemEnabled!
                                    ? theme.colorScheme.secondary
                                    : theme.disabledColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (rowMediaControls)
                      MediaControls(inputName: this.sceneItem.sourceName!),
                    if (!isGroup && isTextInputKind(this.sceneItem.inputKind))
                      Semantics(
                        button: true,
                        label: 'Edit text of ${this.sceneItem.sourceName}',
                        excludeSemantics: true,
                        child: Pressable(
                          onTap: () =>
                              ModalHandler.showBaseCupertinoBottomSheet(
                                context: context,
                                modalWidgetBuilder: (context, controller) =>
                                    TextSourceSheet(
                                      inputName: this.sceneItem.sourceName!,
                                    ),
                              ),
                          child: const SizedBox(
                            width: kBaseIconButtonMinHitArea,
                            height: kBaseIconButtonMinHitArea,
                            child: Center(
                              child: Icon(
                                CupertinoIcons.textformat,
                                size: 20.0,
                              ),
                            ),
                          ),
                        ),
                      ),

                    /// Lock (OBS canvas: no accidental move / resize). Groups skip
                    /// it - their children carry the lock that matters - and media
                    /// rows with their own transport give it the slot (row width on
                    /// phones)
                    if (!isGroup &&
                        !rowMediaControls &&
                        this.sceneItem.sceneItemLocked != null)
                      HiveBuilder<dynamic>(
                        hiveKey: HiveKeys.Settings,
                        rebuildKeys: const [SettingsKeys.ExposeStudioControls],
                        builder: (context, settingsBox, child) => Semantics(
                          button: true,
                          label: this.sceneItem.sceneItemLocked!
                              ? 'Unlock ${this.sceneItem.sourceName}'
                              : 'Lock ${this.sceneItem.sourceName}',
                          excludeSemantics: true,
                          child: Pressable(
                            haptic: true,
                            onTap: () => dashboardStore.sendMutation(
                              RequestType.SetSceneItemLocked,
                              fields: {
                                'sceneName': this._sceneName(
                                  dashboardStore,
                                  settingsBox,
                                ),
                                'sceneItemId': this.sceneItem.sceneItemId,
                                'sceneItemLocked':
                                    !this.sceneItem.sceneItemLocked!,
                              },
                              label: 'Source lock',
                            ),
                            child: SizedBox(
                              width: kBaseIconButtonMinHitArea,
                              height: kBaseIconButtonMinHitArea,
                              child: Center(
                                child: AnimatedToggleIcon(
                                  icon: this.sceneItem.sceneItemLocked!
                                      ? CupertinoIcons.lock_fill
                                      : CupertinoIcons.lock_open,
                                  color: this.sceneItem.sceneItemLocked!
                                      ? theme.colorScheme.onSurface
                                      : theme.disabledColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Semantics(
                      button: true,
                      enabled: this.sceneItem.filters.isNotEmpty,
                      label: 'Filters of ${this.sceneItem.sourceName}',
                      excludeSemantics: true,
                      child: Pressable(
                        onTap: this.sceneItem.filters.isNotEmpty
                            ? () => ModalHandler.showBaseCupertinoBottomSheet(
                                context: context,
                                modalWidgetBuilder: (context, controller) =>
                                    FilterList(sceneItem: this.sceneItem),
                              )
                            : null,
                        child: SizedBox(
                          width: kBaseIconButtonMinHitArea,
                          height: kBaseIconButtonMinHitArea,
                          child: Center(
                            child: Icon(
                              CupertinoIcons.color_filter,
                              color: this.sceneItem.filters.isNotEmpty
                                  ? null
                                  : theme.disabledColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
