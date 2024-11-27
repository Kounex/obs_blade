import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_content/scene_items/filter_list/filter_list.dart';

import '../../../../../../shared/general/hive_builder.dart';
import '../../../../../../stores/shared/network.dart';
import '../../../../../../stores/views/dashboard.dart';
import '../../../../../../types/classes/api/scene_item.dart';
import '../../../../../../types/enums/hive_keys.dart';
import '../../../../../../types/enums/request_type.dart';
import '../../../../../../types/enums/settings_keys.dart';
import '../../../../../../utils/network_helper.dart';

class SceneItemTile extends StatelessWidget {
  final SceneItem sceneItem;

  const SceneItemTile({
    super.key,
    required this.sceneItem,
  });

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    return ListTile(
      dense: true,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (this.sceneItem.parentGroupName != null) ...[
            const SizedBox(width: 4.0),
            const Icon(Icons.subdirectory_arrow_right_sharp),
            const SizedBox(width: 16.0),
          ],
          GestureDetector(
            onTap: () => (!GetIt.instance<DashboardStore>()
                        .editAudioVisibility &&
                    !GetIt.instance<DashboardStore>().editSceneItemVisibility)
                ? GetIt.instance<DashboardStore>()
                    .toggleSceneItemGroupVisibility(this.sceneItem)
                : null,
            child: Icon(
              (this.sceneItem.isGroup ?? false)
                  ? this.sceneItem.displayGroup
                      ? CupertinoIcons.folder
                      : CupertinoIcons.folder_solid
                  : CupertinoIcons.photo_on_rectangle,
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
            builder: (context, settingsBox, child) => IconButton(
              icon: Icon(
                this.sceneItem.sceneItemEnabled!
                    ? Icons.visibility
                    : Icons.visibility_off,
                color: this.sceneItem.sceneItemEnabled!
                    ? Theme.of(context).buttonTheme.colorScheme!.primary
                    : CupertinoColors.destructiveRed,
              ),
              onPressed: () => NetworkHelper.makeRequest(
                GetIt.instance<NetworkStore>().activeSession!.socket,
                RequestType.SetSceneItemEnabled,
                {
                  /// Groups in WebSocket 5.X and higher is weird, therefore
                  /// we need to use the parents scene item name as the
                  /// 'sceneName' property if we are toggling a child of a
                  /// group...
                  'sceneName': this.sceneItem.parentGroupName ??
                      (settingsBox.get(SettingsKeys.ExposeStudioControls.name,
                                  defaultValue: false) &&
                              dashboardStore.studioMode
                          ? dashboardStore.studioModePreviewSceneName
                          : dashboardStore.activeSceneName),
                  'sceneItemId': this.sceneItem.sceneItemId,
                  'sceneItemEnabled': !this.sceneItem.sceneItemEnabled!,
                },
              ),
            ),
          ),
          IconButton(
            onPressed: this.sceneItem.filters.isNotEmpty
                ? () => ModalHandler.showBaseCupertinoBottomSheet(
                      context: context,
                      modalWidgetBuilder: (context, controller) =>
                          FilterList(sceneItem: this.sceneItem),
                    )
                : null,
            icon: const Icon(CupertinoIcons.color_filter),
          )
        ],
      ),
    );
  }
}
