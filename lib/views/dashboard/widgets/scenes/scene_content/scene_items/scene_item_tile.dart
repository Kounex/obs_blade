import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/classes/api/scene_item.dart';
import 'package:obs_blade/types/enums/request_type.dart';
import 'package:obs_blade/utils/icons/cupertino_icons_extended.dart';
import 'package:obs_blade/utils/network_helper.dart';
import 'package:provider/provider.dart';

class SceneItemTile extends StatelessWidget {
  final SceneItem sceneItem;

  SceneItemTile({@required this.sceneItem});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Padding(
        padding: EdgeInsets.only(
            left: this.sceneItem.parentGroupName != null ? 42.0 : 0.0),
        child: GestureDetector(
          onTap: () => context
              .read<DashboardStore>()
              .toggleSceneItemGroupVisibility(this.sceneItem),
          child: Icon(
            this.sceneItem.type == 'group'
                ? this.sceneItem.displayGroup
                    ? CupertinoIcons.folder
                    : CupertinoIcons.folder_solid
                : CupertinoIconsExtended.landscape_image,
          ),
        ),
      ),
      title: Text(
        this.sceneItem.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: Icon(
          this.sceneItem.render ? Icons.visibility : Icons.visibility_off,
          color: this.sceneItem.render
              ? Theme.of(context).accentColor
              : Colors.red,
        ),
        onPressed: () => NetworkHelper.makeRequest(
            context.read<NetworkStore>().activeSession.socket,
            RequestType.SetSceneItemProperties,
            {'item': this.sceneItem.name, 'visible': !this.sceneItem.render}),
      ),
    );
  }
}
