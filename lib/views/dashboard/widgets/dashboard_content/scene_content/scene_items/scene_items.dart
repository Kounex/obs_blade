import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../shared/general/nested_list_manager.dart';
import '../../../../../../stores/views/dashboard.dart';
import '../placeholder_scene_item.dart';
import '../visibility_slide_wrapper.dart';
import 'scene_item_tile.dart';

class SceneItems extends StatefulWidget {
  const SceneItems({
    super.key,
  });

  @override
  _SceneItemsState createState() => _SceneItemsState();
}

class _SceneItemsState extends State<SceneItems>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _controller = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    return Observer(builder: (context) {
      return NestedScrollManager(
        parentScrollController:
            ModalRoute.of(context)!.settings.arguments as ScrollController,
        child: Scrollbar(
          controller: _controller,
          thumbVisibility: true,
          child: ListView(
            controller: _controller,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.only(top: 12.0),
            children: [
              ...dashboardStore.currentSceneItems.isNotEmpty
                  ? dashboardStore.currentSceneItems
                      .where(
                        (sceneItem) =>
                            sceneItem.parentGroupName == null ||
                            (sceneItem.parentGroupName != null &&
                                dashboardStore.currentSceneItems
                                    .firstWhere((parentSceneItem) =>
                                        parentSceneItem.sourceName ==
                                        sceneItem.parentGroupName)
                                    .displayGroup),
                      )
                      .map(
                        (sceneItem) => VisibilitySlideWrapper(
                          sceneItem: sceneItem,
                          child: SceneItemTile(
                            sceneItem: sceneItem,
                          ),
                        ),
                      )
                  : [
                      const SizedBox(height: 12.0),
                      const PlaceholderSceneItem(
                          text: 'No Scene Items available...')
                    ]
            ],
          ),
        ),
      );
    });
  }
}
