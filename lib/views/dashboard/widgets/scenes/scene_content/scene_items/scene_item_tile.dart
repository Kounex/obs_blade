import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  SceneItemTile({required this.sceneItem});

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = context.read<DashboardStore>();

    return ListTile(
      dense: true,
      leading: Padding(
        padding: EdgeInsets.only(
            left: this.sceneItem.parentGroupName != null ? 42.0 : 0.0),
        child: GestureDetector(
          onTap: () => (!context.read<DashboardStore>().editAudioVisibility &&
                  !context.read<DashboardStore>().editSceneItemVisibility)
              ? context
                  .read<DashboardStore>()
                  .toggleSceneItemGroupVisibility(this.sceneItem)
              : null,
          child: Icon(
            this.sceneItem.type == 'group'
                ? this.sceneItem.displayGroup
                    ? CupertinoIcons.folder
                    : CupertinoIcons.folder_solid
                : CupertinoIcons.photo_on_rectangle,
          ),
        ),
      ),
      title: Text(
        this.sceneItem.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: HiveBuilder<dynamic>(
        hiveKey: HiveKeys.Settings,
        rebuildKeys: [SettingsKeys.ExposeStudioControls],
        builder: (context, settingsBox, child) => IconButton(
          icon: Icon(
            this.sceneItem.render! ? Icons.visibility : Icons.visibility_off,
            color: this.sceneItem.render!
                ? Theme.of(context).buttonColor
                : CupertinoColors.destructiveRed,
          ),
          onPressed: () => NetworkHelper.makeRequest(
              context.read<NetworkStore>().activeSession!.socket,
              RequestType.SetSceneItemProperties, {
            'scene-name': settingsBox.get(
                        SettingsKeys.ExposeStudioControls.name,
                        defaultValue: false) &&
                    dashboardStore.studioMode
                ? dashboardStore.studioModePreviewSceneName
                : dashboardStore.activeSceneName,
            'item': this.sceneItem.name,
            'visible': !this.sceneItem.render!,
          }),
        ),
      ),
    );
  }
}
