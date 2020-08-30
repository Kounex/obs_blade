import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../../../../../stores/views/dashboard.dart';
import '../nested_list_manager.dart';
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
      dashboardStore.currentSceneItems
          ?.forEach((element) => print(element.type));

      return NestedScrollManager(
        child: Scrollbar(
          controller: _controller,
          isAlwaysShown: true,
          child: ListView(
            controller: _controller,
            physics: ClampingScrollPhysics(),
            padding: EdgeInsets.all(0.0),
            itemExtent: 50.0,
            children: [
              ...dashboardStore.currentSceneItems.length > 0
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
                  : [
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Center(
                          child: Text('No Scene Items available...'),
                        ),
                      )
                    ]
            ],
          ),
        ),
      );
    });
  }
}
