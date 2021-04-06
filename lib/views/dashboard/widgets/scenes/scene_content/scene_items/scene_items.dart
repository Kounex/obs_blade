import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../../../../../models/enums/scene_item_type.dart';
import '../../../../../../shared/general/nested_list_manager.dart';
import '../../../../../../stores/views/dashboard.dart';
import '../placeholder_scene_item.dart';
import '../visibility_slide_wrapper.dart';
import 'scene_item_tile.dart';

class SceneItems extends StatefulWidget {
  @override
  _SceneItemsState createState() => _SceneItemsState();
}

class _SceneItemsState extends State<SceneItems>
    with AutomaticKeepAliveClientMixin {
  ScrollController _controller = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    DashboardStore dashboardStore = Provider.of<DashboardStore>(context);

    return Observer(builder: (_) {
      return NestedScrollManager(
        parentScrollController:
            ModalRoute.of(context)!.settings.arguments as ScrollController,
        child: Scrollbar(
          controller: _controller,
          isAlwaysShown: true,
          child: ListView(
            controller: _controller,
            physics: ClampingScrollPhysics(),
            padding: EdgeInsets.all(0.0),
            children: [
              ...dashboardStore.currentSceneItems != null &&
                      dashboardStore.currentSceneItems!.length > 0
                  ? dashboardStore.currentSceneItems!
                      .where(
                        (sceneItem) =>
                            sceneItem.parentGroupName == null ||
                            (sceneItem.parentGroupName != null &&
                                dashboardStore.currentSceneItems!
                                    .firstWhere((parentSceneItem) =>
                                        parentSceneItem.name ==
                                        sceneItem.parentGroupName)
                                    .displayGroup),
                      )
                      .map(
                        (sceneItem) => VisibilitySlideWrapper(
                          sceneItem: sceneItem,
                          sceneItemType: SceneItemType.Source,
                          child: SceneItemTile(
                            sceneItem: sceneItem,
                          ),
                        ),
                      )
                  : [PlaceholderSceneItem(text: 'No Scene Items available...')]
            ],
          ),
        ),
      );
    });
  }
}
