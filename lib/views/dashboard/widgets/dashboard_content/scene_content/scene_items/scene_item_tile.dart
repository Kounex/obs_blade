import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_content/scene_items/filter_list/filter_list.dart';

import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/general/hive_builder.dart';
import '../../../../../../stores/shared/network.dart';
import '../../../../../../stores/views/dashboard.dart';
import '../../../../../../types/classes/api/scene_item.dart';
import '../../../../../../types/enums/hive_keys.dart';
import '../../../../../../types/enums/request_type.dart';
import '../../../../../../types/enums/settings_keys.dart';
import '../../../../../../utils/network_helper.dart';
import '../animated_toggle_icon.dart';

class SceneItemTile extends StatelessWidget {
  final SceneItem sceneItem;

  const SceneItemTile({
    super.key,
    required this.sceneItem,
  });

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

    /// Group rows forward the tap of the whole row to the same group
    /// visibility toggle the leading icon already exposes (still gated on
    /// the visibility edit mode)
    return Pressable(
      onTap: isGroup &&
              !dashboardStore.editAudioVisibility &&
              !dashboardStore.editSceneItemVisibility
          ? () => dashboardStore.toggleSceneItemGroupVisibility(this.sceneItem)
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
              onTap: () => (!dashboardStore.editAudioVisibility &&
                      !dashboardStore.editSceneItemVisibility)
                  ? dashboardStore
                      .toggleSceneItemGroupVisibility(this.sceneItem)
                  : null,
              child: AnimatedSwitcher(
                duration: AppMotion.fast,
                switchInCurve: AppMotion.standard,
                switchOutCurve: AppMotion.exit,
                child: Icon(
                  typeIcon,
                  key: ValueKey(typeIcon),
                ),
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
              rebuildKeys: const [
                SettingsKeys.ExposeStudioControls,
              ],
              builder: (context, settingsBox, child) => Pressable(
                haptic: true,
                onTap: () => NetworkHelper.makeRequest(
                  GetIt.instance<NetworkStore>().activeSession!.socket,
                  RequestType.SetSceneItemEnabled,
                  {
                    /// Groups in WebSocket 5.X and higher is weird, therefore
                    /// we need to use the parents scene item name as the
                    /// 'sceneName' property if we are toggling a child of a
                    /// group...
                    'sceneName': this.sceneItem.parentGroupName ??
                        (settingsBox.get(
                                    SettingsKeys.ExposeStudioControls.name,
                                    defaultValue: false) &&
                                dashboardStore.studioMode
                            ? dashboardStore.studioModePreviewSceneName
                            : dashboardStore.activeSceneName),
                    'sceneItemId': this.sceneItem.sceneItemId,
                    'sceneItemEnabled': !this.sceneItem.sceneItemEnabled!,
                  },
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: AnimatedToggleIcon(
                    icon: this.sceneItem.sceneItemEnabled!
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: this.sceneItem.sceneItemEnabled!
                        ? theme.buttonTheme.colorScheme!.primary
                        : theme.disabledColor,
                  ),
                ),
              ),
            ),
            Pressable(
              onTap: this.sceneItem.filters.isNotEmpty
                  ? () => ModalHandler.showBaseCupertinoBottomSheet(
                        context: context,
                        modalWidgetBuilder: (context, controller) =>
                            FilterList(sceneItem: this.sceneItem),
                      )
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Icon(
                  CupertinoIcons.color_filter,
                  color: this.sceneItem.filters.isNotEmpty
                      ? null
                      : theme.disabledColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
