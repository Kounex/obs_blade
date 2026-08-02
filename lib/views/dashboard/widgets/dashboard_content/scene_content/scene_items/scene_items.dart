import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../shared/design/design.dart';
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
            padding: const EdgeInsets.only(top: AppSpacing.md),
            children: [
              ...dashboardStore.currentSceneItems.isNotEmpty
                  ? dashboardStore.currentSceneItems.map(
                      (sceneItem) {
                        if (sceneItem.parentGroupName == null) {
                          return VisibilitySlideWrapper(
                            sceneItem: sceneItem,
                            child: SceneItemTile(
                              sceneItem: sceneItem,
                            ),
                          );
                        }

                        /// Children of groups stay in the tree so collapsing
                        /// / expanding the group animates - visibility is
                        /// still driven by the parents [SceneItem.displayGroup]
                        return _AnimatedGroupChild(
                          visible: dashboardStore.currentSceneItems
                              .firstWhere((parentSceneItem) =>
                                  parentSceneItem.sourceName ==
                                  sceneItem.parentGroupName)
                              .displayGroup,
                          child: VisibilitySlideWrapper(
                            sceneItem: sceneItem,
                            child: SceneItemTile(
                              sceneItem: sceneItem,
                            ),
                          ),
                        );
                      },
                    )
                  : [
                      const SizedBox(height: AppSpacing.md),
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

/// Animates a group child row in and out (size + fade) when the parent
/// group's `displayGroup` flag toggles
class _AnimatedGroupChild extends StatelessWidget {
  final bool visible;
  final Widget child;

  const _AnimatedGroupChild({
    required this.visible,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: AppMotion.medium,
      curve: AppMotion.standard,
      alignment: Alignment.topCenter,
      child: ClipRect(
        child: IgnorePointer(
          ignoring: !this.visible,
          child: AnimatedOpacity(
            duration: AppMotion.medium,
            opacity: this.visible ? 1.0 : 0.0,
            child: SizedBox(
              width: double.infinity,
              height: this.visible ? null : 0.0,
              child: this.child,
            ),
          ),
        ),
      ),
    );
  }
}
