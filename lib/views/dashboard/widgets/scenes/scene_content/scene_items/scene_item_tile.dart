import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

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
    Key? key,
    required this.sceneItem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    return ListTile(
      dense: true,
      leading: Padding(
        padding: EdgeInsets.only(
            left: this.sceneItem.parentGroupName != null ? 42.0 : 0.0),
        child: GestureDetector(
          onTap: () => (!GetIt.instance<DashboardStore>().editAudioVisibility &&
                  !GetIt.instance<DashboardStore>().editSceneItemVisibility)
              ? GetIt.instance<DashboardStore>()
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
        rebuildKeys: const [SettingsKeys.ExposeStudioControls],
        builder: (context, settingsBox, child) => IconButton(
          icon: Icon(
            this.sceneItem.render! ? Icons.visibility : Icons.visibility_off,
            color: this.sceneItem.render!
                ? Theme.of(context).buttonColor
                : CupertinoColors.destructiveRed,
          ),
          onPressed: () => NetworkHelper.makeRequest(
              GetIt.instance<NetworkStore>().activeSession!.socket,
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
