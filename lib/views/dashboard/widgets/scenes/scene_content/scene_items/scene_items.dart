import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:obs_blade/views/dashboard/widgets/scenes/scene_content/placeholder_scene_item.dart';
import 'package:provider/provider.dart';

import '../../../../../../stores/views/dashboard.dart';
import '../../../../../../shared/general/nested_list_manager.dart';
import 'scene_item_tile.dart';

class SceneItems extends StatefulWidget {
  @override
  _SceneItemsState createState() => _SceneItemsState();
}

class _SceneItemsState extends State<SceneItems> {
  ScrollController _controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = Provider.of<DashboardStore>(context);

    return Observer(builder: (_) {
      dashboardStore.currentAudioSceneItems?.forEach((element) =>
          print('${element.id}: ${element.name} (${element.type})'));

      dashboardStore.globalAudioSceneItems?.forEach((element) =>
          print('${element.id}: ${element.name} (${element.type})'));

      return NestedScrollManager(
        parentScrollController: ModalRoute.of(context).settings.arguments,
        child: Scrollbar(
          controller: _controller,
          isAlwaysShown: true,
          child: ListView(
            controller: _controller,
            physics: ClampingScrollPhysics(),
            padding: EdgeInsets.all(0.0),
            itemExtent: 50.0,
            children: [
              ...dashboardStore.currentSceneItems != null &&
                      dashboardStore.currentSceneItems.length > 0
                  ? dashboardStore.currentSceneItems
                      .where((sceneItem) =>
                          sceneItem.parentGroupName == null ||
                          (sceneItem.parentGroupName != null &&
                              dashboardStore.currentSceneItems
                                  .firstWhere((parentSceneItem) =>
                                      parentSceneItem.name ==
                                      sceneItem.parentGroupName)
                                  .displayGroup))
                      .map((sceneItem) => SceneItemTile(
                            sceneItem: sceneItem,
                          ))
                  : [PlaceholderSceneItem(text: 'No Scene Items available...')]
            ],
          ),
        ),
      );
    });
  }
}
