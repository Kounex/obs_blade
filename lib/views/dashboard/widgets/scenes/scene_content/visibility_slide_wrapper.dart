import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/models/enums/scene_item_type.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/types/classes/api/input.dart';

import '../../../../../models/hidden_scene_item.dart';
import '../../../../../shared/general/hive_builder.dart';
import '../../../../../stores/views/dashboard.dart';
import '../../../../../types/classes/api/scene_item.dart';
import '../../../../../types/enums/hive_keys.dart';

class VisibilitySlideWrapper extends StatefulWidget {
  final SceneItem? sceneItem;
  final Input? input;
  final Widget child;

  const VisibilitySlideWrapper(
      {Key? key, required this.child, this.sceneItem, this.input})
      : assert(sceneItem != null || input != null),
        super(key: key);

  @override
  _VisibilitySlideWrapperState createState() => _VisibilitySlideWrapperState();
}

class _VisibilitySlideWrapperState extends State<VisibilitySlideWrapper> {
  // SlidableController _controller = SlidableController();

  final List<ReactionDisposer> _disposers = [];

  @override
  void dispose() {
    for (var d in _disposers) {
      d();
    }
    super.dispose();
  }

  void _registerReaction(
      DashboardStore dashboardStore, SlidableController slidableController) {
    _disposers.add(
      reaction(
        this.widget.sceneItem != null
            ? (_) => dashboardStore.editSceneItemVisibility
            : (_) => dashboardStore.editAudioVisibility,
        (bool editVisibility) {
          Future.delayed(
            const Duration(milliseconds: 50),
            () => editVisibility
                ? slidableController.openStartActionPane()
                : slidableController.close(),
          );
        },
      ),
    );
  }

  bool _isItemHidden(
      DashboardStore dashboardStore,
      Box<HiddenSceneItem> hiddenSceneItemsBox,
      HiddenSceneItem? hiddenSceneItem) {
    bool isEditing = this.widget.sceneItem != null
        ? dashboardStore.editSceneItemVisibility
        : dashboardStore.editAudioVisibility;

    if (isEditing) {
      return false;
    } else {
      if (hiddenSceneItem != null) {
        return true;
      } else if (this.widget.sceneItem != null &&
          this.widget.sceneItem!.parentGroupName != null) {
        bool parentHidden = hiddenSceneItemsBox.values.toList().any(
              (hiddenSceneItemInBox) =>
                  hiddenSceneItemInBox.name ==
                      this.widget.sceneItem!.parentGroupName &&
                  (hiddenSceneItemInBox.sourceType != null
                      ? hiddenSceneItemInBox.sourceType == 'group'
                      : true),
            );

        return parentHidden;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();
    NetworkStore networkStore = GetIt.instance<NetworkStore>();

    return HiveBuilder<HiddenSceneItem>(
      hiveKey: HiveKeys.HiddenSceneItem,
      builder: (context, hiddenSceneItemsBox, child) {
        HiddenSceneItem? hiddenSceneItem;
        try {
          hiddenSceneItem = hiddenSceneItemsBox.values.toList().firstWhere(
                (hiddenSceneItem) => hiddenSceneItem.isSceneItem(
                  dashboardStore.activeSceneName!,
                  this.widget.sceneItem != null
                      ? SceneItemType.Source
                      : SceneItemType.Audio,
                  this.widget.sceneItem?.sceneItemId,
                  this.widget.sceneItem?.sourceName ??
                      this.widget.input!.inputName!,
                  networkStore.activeSession?.connection.name,
                  networkStore.activeSession?.connection.host,
                ),
              );
        } catch (e) {
          hiddenSceneItem = null;
        }

        return Observer(
          builder: (_) => Offstage(
            offstage: _isItemHidden(
                dashboardStore, hiddenSceneItemsBox, hiddenSceneItem),
            child: Slidable(
              closeOnScroll: false,
              enabled: false,
              startActionPane: ActionPane(
                motion: const BehindMotion(),
                extentRatio: 0.2,
                children: [
                  CustomSlidableAction(
                    backgroundColor: hiddenSceneItem != null
                        ? CupertinoColors.destructiveRed
                        : Theme.of(context).buttonTheme.colorScheme!.primary,
                    autoClose: false,
                    onPressed: (_) {
                      if (hiddenSceneItem != null) {
                        hiddenSceneItem!.delete();
                      } else {
                        hiddenSceneItem = HiddenSceneItem(
                          dashboardStore.activeSceneName!,
                          this.widget.sceneItem != null
                              ? SceneItemType.Source
                              : SceneItemType.Audio,
                          this.widget.sceneItem?.sceneItemId,
                          this.widget.sceneItem?.sourceName ??
                              this.widget.input!.inputName!,
                          this.widget.sceneItem?.sourceType,
                          networkStore.activeSession?.connection.name,
                          networkStore.activeSession?.connection.host,
                        );

                        hiddenSceneItemsBox.add(hiddenSceneItem!);
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Icon(
                            hiddenSceneItem != null
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 18.0,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Flexible(
                          child: Text(
                            hiddenSceneItem != null ? 'Hidden' : 'Visible',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(fontSize: 12.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              child: Builder(
                builder: (context) {
                  _registerReaction(dashboardStore, Slidable.of(context)!);
                  return this.widget.child;
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
