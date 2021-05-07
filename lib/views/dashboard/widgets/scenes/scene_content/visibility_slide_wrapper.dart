import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

import '../../../../../models/enums/scene_item_type.dart';
import '../../../../../models/hidden_scene_item.dart';
import '../../../../../shared/general/hive_builder.dart';
import '../../../../../stores/views/dashboard.dart';
import '../../../../../types/classes/api/scene_item.dart';
import '../../../../../types/enums/hive_keys.dart';

class VisibilitySlideWrapper extends StatefulWidget {
  final SceneItem sceneItem;
  final SceneItemType sceneItemType;
  final Widget child;

  VisibilitySlideWrapper({
    required this.child,
    required this.sceneItem,
    required this.sceneItemType,
  });

  @override
  _VisibilitySlideWrapperState createState() => _VisibilitySlideWrapperState();
}

class _VisibilitySlideWrapperState extends State<VisibilitySlideWrapper> {
  SlidableController _controller = SlidableController();

  List<ReactionDisposer> _disposers = [];

  @override
  void dispose() {
    _disposers.forEach((d) => d());
    super.dispose();
  }

  void _registerReaction(
      DashboardStore dashboardStore, SlidableState slidableState) {
    _disposers.add(
      reaction(
        this.widget.sceneItemType == SceneItemType.Source
            ? (_) => dashboardStore.editSceneItemVisibility
            : (_) => dashboardStore.editAudioVisibility,
        (bool editVisibility) {
          Future.delayed(
              Duration(milliseconds: 50),
              () => editVisibility
                  ? slidableState.open()
                  : slidableState.close());
        },
      ),
    );
  }

  bool _isItemHidden(
      DashboardStore dashboardStore,
      Box<HiddenSceneItem> hiddenSceneItemsBox,
      HiddenSceneItem? hiddenSceneItem) {
    bool isEditing = this.widget.sceneItemType == SceneItemType.Source
        ? dashboardStore.editSceneItemVisibility
        : dashboardStore.editAudioVisibility;

    if (isEditing) {
      return false;
    } else {
      if (hiddenSceneItem != null) {
        return true;
      } else if (this.widget.sceneItem.parentGroupName != null) {
        bool parentHidden = hiddenSceneItemsBox.values.toList().any(
            (hiddenSceneItemInBox) =>
                hiddenSceneItemInBox.name ==
                    this.widget.sceneItem.parentGroupName &&
                (hiddenSceneItemInBox.sourceType != null
                    ? hiddenSceneItemInBox.sourceType == 'group'
                    : true));

        return parentHidden;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    return HiveBuilder<HiddenSceneItem>(
      hiveKey: HiveKeys.HiddenSceneItem,
      builder: (context, hiddenSceneItemsBox, child) {
        HiddenSceneItem? hiddenSceneItem;
        try {
          hiddenSceneItem = hiddenSceneItemsBox.values.toList().firstWhere(
                (hiddenSceneItem) => hiddenSceneItem.isSceneItem(
                    dashboardStore.activeSceneName!,
                    this.widget.sceneItemType,
                    this.widget.sceneItem),
              );
        } catch (e) {
          hiddenSceneItem = null;
        }

        return Observer(
          builder: (_) => Offstage(
            offstage: _isItemHidden(
                dashboardStore, hiddenSceneItemsBox, hiddenSceneItem),
            // (this.widget.sceneItem.parentGroupName != null &&
            //             hiddenSceneItemsBox.values.toList().any(
            //                 (hiddenParent) =>
            //                     hiddenParent.name ==
            //                         this.widget.sceneItem.parentGroupName &&
            //                     (hiddenParent.sourceType != null
            //                         ? hiddenParent.sourceType == 'group'
            //                         : true)) ||
            //         hiddenSceneItem != null) &&
            //     !(this.widget.sceneItemType == SceneItemType.Source
            //         ? dashboardStore.editSceneItemVisibility
            //         : dashboardStore.editAudioVisibility),
            child: Slidable(
              controller: _controller,
              closeOnScroll: false,
              actionPane: SlidableScrollActionPane(),
              actionExtentRatio: 0.2,
              child: Builder(
                builder: (context) {
                  _registerReaction(dashboardStore, Slidable.of(context)!);
                  return this.widget.child;
                },
              ),
              actions: [
                IconSlideAction(
                  caption: hiddenSceneItem != null ? 'Hidden' : 'Visible',
                  color: hiddenSceneItem != null
                      ? CupertinoColors.destructiveRed
                      : Theme.of(context).buttonColor,
                  icon: hiddenSceneItem != null
                      ? Icons.visibility_off
                      : Icons.visibility,
                  closeOnTap: false,
                  onTap: () {
                    if (hiddenSceneItem != null) {
                      // if (hiddenSceneItemsBox.values.toList().where((hiddenChildItem) => hiddenChildItem.))
                      hiddenSceneItem!.delete();
                    } else {
                      hiddenSceneItem = HiddenSceneItem(
                        dashboardStore.activeSceneName!,
                        this.widget.sceneItemType,
                        this.widget.sceneItem.id,
                        this.widget.sceneItem.name,
                        this.widget.sceneItem.type,
                      );

                      hiddenSceneItemsBox.add(hiddenSceneItem!);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
