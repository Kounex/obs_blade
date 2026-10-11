import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/models/enums/scene_item_type.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/types/classes/api/input.dart';

import '../../../../../models/hidden_scene_item.dart';
import '../../../../../shared/design/design.dart';
import '../../../../../shared/general/hive_builder.dart';
import '../../../../../stores/views/dashboard.dart';
import '../../../../../types/classes/api/scene_item.dart';
import '../../../../../types/enums/hive_keys.dart';
import 'animated_toggle_icon.dart';

class VisibilitySlideWrapper extends StatefulWidget {
  final SceneItem? sceneItem;
  final Input? input;
  final Widget child;

  /// Scene the item belongs to - defaults to the program scene; set for a
  /// scene of another canvas ([canvasName])
  final String? sceneName;

  /// OBS canvas of [sceneName] - null = main canvas. Hidden entries are
  /// stored per canvas since scene names can repeat across canvases
  final String? canvasName;

  const VisibilitySlideWrapper({
    super.key,
    required this.child,
    this.sceneItem,
    this.input,
    this.sceneName,
    this.canvasName,
  }) : assert(sceneItem != null || input != null);

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
    DashboardStore dashboardStore,
    SlidableController slidableController,
  ) {
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
    HiddenSceneItem? hiddenSceneItem,
  ) {
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
              hiddenSceneItemInBox.canvasName == this.widget.canvasName &&
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
    final String? sceneName =
        this.widget.sceneName ?? dashboardStore.activeSceneName;

    return HiveBuilder<HiddenSceneItem>(
      hiveKey: HiveKeys.HiddenSceneItem,
      builder: (context, hiddenSceneItemsBox, child) {
        HiddenSceneItem? hiddenSceneItem;
        try {
          hiddenSceneItem = hiddenSceneItemsBox.values.toList().firstWhere(
            (hiddenSceneItem) => hiddenSceneItem.isSceneItem(
              sceneName!,
              this.widget.sceneItem != null
                  ? SceneItemType.Source
                  : SceneItemType.Audio,
              this.widget.sceneItem?.sceneItemId,
              this.widget.sceneItem?.sourceName ??
                  this.widget.input!.inputName!,
              networkStore.activeSession?.connection.name,
              networkStore.activeSession?.connection.host,
              canvasName: this.widget.canvasName,
            ),
          );
        } catch (e) {
          hiddenSceneItem = null;
        }

        /// Visibility affordances follow the lock's on/off color language:
        /// active (visible) is onSurface, inactive (hidden) is
        /// disabledColor - red stays exclusive to recording / program
        final Color actionColor = hiddenSceneItem != null
            ? Theme.of(context).disabledColor
            : Theme.of(context).colorScheme.onSurface;

        return Observer(
          builder: (context) => Offstage(
            offstage: _isItemHidden(
              dashboardStore,
              hiddenSceneItemsBox,
              hiddenSceneItem,
            ),
            child: Slidable(
              closeOnScroll: false,
              enabled: false,
              startActionPane: ActionPane(
                motion: const BehindMotion(),
                extentRatio: 0.3,
                children: [
                  /// The whole pane is the hit area. Pressable instead of
                  /// CustomSlidableAction: that one's OutlinedButton painted
                  /// a Material ink splash across the pane - taps here get
                  /// the press scale / dim the row toggles use
                  Expanded(
                    child: Semantics(
                      button: true,
                      child: Pressable(
                        haptic: true,
                        onTap: () {
                          if (hiddenSceneItem != null) {
                            hiddenSceneItem!.delete();
                          } else {
                            hiddenSceneItem = HiddenSceneItem(
                              sceneName!,
                              this.widget.sceneItem != null
                                  ? SceneItemType.Source
                                  : SceneItemType.Audio,
                              this.widget.sceneItem?.sceneItemId,
                              this.widget.sceneItem?.sourceName ??
                                  this.widget.input!.inputName!,
                              this.widget.sceneItem?.sourceType,
                              networkStore.activeSession?.connection.name,
                              networkStore.activeSession?.connection.host,
                              this.widget.canvasName,
                            );

                            hiddenSceneItemsBox.add(hiddenSceneItem!);
                          }
                        },

                        /// Wide (tablet) panes keep the pill at the leading
                        /// edge instead of floating it far from its row
                        child: SizedBox.expand(
                          child: Align(
                            alignment: Alignment.centerLeft,

                            /// Status-pill grammar (LIVE / REC): one 28pt
                            /// pill, icon + label side by side - visible is
                            /// lit like an active pill, hidden is the
                            /// neutral hairline one. The pane only aligns
                            /// it, so the pill gets a fixed width (capped
                            /// for wide tablet panes) and scales its
                            /// content down on narrow phones instead of
                            /// clipping
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: AppSpacing.lg,
                                right: AppSpacing.sm,
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 104.0,
                                ),
                                child: AnimatedContainer(
                                  duration: AppMotion.fast,
                                  curve: AppMotion.standard,
                                  width: double.infinity,
                                  height: 28.0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: AppRadius.pill,
                                    color: hiddenSceneItem != null
                                        ? Colors.transparent
                                        : actionColor.withValues(alpha: 0.14),
                                    border: Border.all(
                                      color: hiddenSceneItem != null
                                          ? Theme.of(context).dividerColor
                                                .withValues(alpha: 0.4)
                                          : actionColor.withValues(alpha: 0.45),
                                    ),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AnimatedToggleIcon(
                                          icon: hiddenSceneItem != null
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: actionColor,
                                          size: 16.0,
                                        ),
                                        const SizedBox(width: 6.0),
                                        Text(
                                          hiddenSceneItem != null
                                              ? 'Hidden'
                                              : 'Visible',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium!
                                              .copyWith(color: actionColor),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
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
