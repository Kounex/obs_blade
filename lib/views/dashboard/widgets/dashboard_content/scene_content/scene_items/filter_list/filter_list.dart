import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/base/card.dart';
import 'package:obs_blade/shared/general/base/divider.dart';
import 'package:obs_blade/shared/general/base/sheet.dart';
import 'package:obs_blade/shared/general/base/icon_button.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/classes/api/scene_item.dart';
import 'package:obs_blade/types/enums/request_type.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_content/scene_items/filter_list/dynamic_input.dart';

import '../../animated_toggle_icon.dart';

class FilterList extends StatefulWidget {
  final SceneItem sceneItem;

  const FilterList({super.key, required this.sceneItem});

  @override
  State<FilterList> createState() => _FilterListState();
}

class _FilterListState extends State<FilterList> {
  /// Shared by the list and its Scrollbar - the sheet route's primary
  /// controller has no scroll view attached (the list isn't primary), so
  /// a Scrollbar without one couldn't be dragged
  final ScrollController _scrollController = ScrollController();
  final List<ReactionDisposer> _d = [];

  late final Timer _timer;

  /// The edited item as last seen in the dashboard's scene items - shown
  /// for the one frame the sheet needs to close once it's gone
  late SceneItem _sceneItem = this.widget.sceneItem;
  bool _closing = false;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      /// The session can end a moment before the sheet closes
      if (GetIt.instance<NetworkStore>().activeSession == null) return;
      GetIt.instance<DashboardStore>().fetchSceneItemsFilters();
    });

    /// Disposed with the sheet - it used to outlive it and pop on a dead
    /// context when OBS quit later
    _d.add(
      when((_) => GetIt.instance<NetworkStore>().obsTerminated, this._close),
    );
  }

  /// Closes the sheet once, after the current frame (never from build)
  void _close() {
    if (_closing) return;
    _closing = true;
    WidgetsBinding.instance
      ..addPostFrameCallback((_) {
        if (this.mounted) Navigator.of(this.context).pop();
      })
      /// A post-frame callback alone waits for some other frame - from the
      /// OBS-quit reaction nothing else rebuilds
      ..ensureVisualUpdate();
  }

  @override
  void dispose() {
    for (final d in _d) {
      d();
    }

    _timer.cancel();
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    return Observer(
      builder: (context) {
        /// The sheet gets the [SceneItem] once, when it opens; filter
        /// updates replace the item in the dashboard's scene items, so the
        /// current one is read from there. When it's gone (scene switched,
        /// item removed) the sheet closes after this frame - popping
        /// during build threw, and the unassigned item crashed the frame.
        final SceneItem? current = dashboardStore.currentSceneItems
            .where(
              (item) => item.sceneItemId == this.widget.sceneItem.sceneItemId,
            )
            .firstOrNull;
        if (current != null) {
          _sceneItem = current;
        } else {
          this._close();
        }
        final SceneItem sceneItem = _sceneItem;
        return BaseSheetScaffold(
          header: BaseSheetTitle('Filters', subtitle: sceneItem.sourceName),
          bodyIsScrollable: true,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'List of filters which are attached to the selected scene item.',
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const BaseDivider(),
                  ],
                ),
              ),
              Expanded(
                child: Scrollbar(
                  controller: _scrollController,
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    children: sceneItem.filters
                        .map(
                          (filter) => BaseCard(
                            leftPadding: AppSpacing.lg,
                            rightPadding: AppSpacing.lg,
                            bottomPadding: 0,
                            title: filter.filterName,
                            titlePadding: const EdgeInsets.symmetric(
                              horizontal: 18.0,
                              vertical: 12.0,
                            ),
                            titleStyle: Theme.of(context).textTheme.bodyLarge,
                            trailingTitleWidget: StaleGuard(
                              child: Pressable(
                                haptic: true,
                                onTap: () => GetIt.instance<DashboardStore>()
                                    .sendMutation(
                                      RequestType.SetSourceFilterEnabled,
                                      fields: {
                                        'sourceName': sceneItem.sourceName,
                                        'filterName': filter.filterName,
                                        'filterEnabled': !filter.filterEnabled,
                                      },
                                      label: 'Filter toggle',
                                    ),
                                child: SizedBox(
                                  width: kBaseIconButtonMinHitArea,
                                  height: kBaseIconButtonMinHitArea,
                                  child: Center(
                                    child: AnimatedToggleIcon(
                                      icon: filter.filterEnabled
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: filter.filterEnabled
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.onSurface
                                          : Theme.of(context).disabledColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            child: Column(
                              children: filter.filterSettings.entries
                                  .map(
                                    (filterSetting) => StaleGuard(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: AppSpacing.sm,
                                        ),
                                        child: DynamicInput(
                                          label: filterSetting.key,
                                          value: filterSetting.value,
                                          onUpdate: (updatedValue) {
                                            GetIt.instance<DashboardStore>()
                                                .sendMutation(
                                                  RequestType
                                                      .SetSourceFilterSettings,
                                                  fields: {
                                                    'sourceName':
                                                        sceneItem.sourceName,
                                                    'filterName':
                                                        filter.filterName,
                                                    'filterSettings': {}
                                                      ..addAll(
                                                        filter.filterSettings,
                                                      )
                                                      ..update(
                                                        filterSetting.key,
                                                        (value) => updatedValue,
                                                      ),
                                                  },
                                                  label: 'Filter settings',
                                                );
                                          },
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
