import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/shared/general/base/card.dart';
import 'package:obs_blade/shared/general/base/divider.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/classes/api/scene_item.dart';
import 'package:obs_blade/types/enums/request_type.dart';
import 'package:obs_blade/utils/network_helper.dart';
import 'package:obs_blade/views/dashboard/widgets/scenes/scene_content/scene_items/filter_list/dynamic_input.dart';

class FilterList extends StatefulWidget {
  final SceneItem sceneItem;

  const FilterList({
    super.key,
    required this.sceneItem,
  });

  @override
  State<FilterList> createState() => _FilterListState();
}

class _FilterListState extends State<FilterList> {
  final List<ReactionDisposer> _d = [];

  late final Timer _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      GetIt.instance<DashboardStore>().fetchSceneItemsFilters();
    });

    when(
      (_) => GetIt.instance<NetworkStore>().obsTerminated,
      () => Navigator.of(context).pop(),
    );
  }

  @override
  void dispose() {
    for (final d in _d) {
      d();
    }

    _timer.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    return Observer(
      builder: (context) {
        /// Hacky approach... this widget will be displayed in a
        /// CupertinoModalBottomSheet which will be provided the [SceneItem]
        /// which filters we are editing. When we update the filters, the
        /// underlying [SceneItem] is updated but not a new one is provided
        /// here in the widget since it's being called imperatively...
        late SceneItem sceneItem;
        try {
          sceneItem = dashboardStore.currentSceneItems.firstWhere(
            (sceneItem) => sceneItem.sceneItemId == sceneItem.sceneItemId,
          );
        } catch (_) {
          Navigator.of(context).pop();
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    sceneItem.sourceName!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12.0),
                  const Text(
                      'List of filters which are attached to the selected scene item.'),
                  const SizedBox(height: 24.0),
                  const BaseDivider(),
                ],
              ),
            ),
            Expanded(
              child: Scrollbar(
                child: ListView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.paddingOf(context).bottom + 12.0,
                  ),
                  children: sceneItem.filters
                      .map(
                        (filter) => BaseCard(
                          leftPadding: 24.0,
                          rightPadding: 24.0,
                          bottomPadding: 0,
                          title: filter.filterName,
                          titlePadding: const EdgeInsets.symmetric(
                            horizontal: 18.0,
                            vertical: 12.0,
                          ),
                          titleStyle: Theme.of(context).textTheme.bodyLarge,
                          trailingTitleWidget: IconButton(
                            onPressed: () => NetworkHelper.makeRequest(
                              GetIt.instance<NetworkStore>()
                                  .activeSession!
                                  .socket,
                              RequestType.SetSourceFilterEnabled,
                              {
                                'sourceName': sceneItem.sourceName,
                                'filterName': filter.filterName,
                                'filterEnabled': !filter.filterEnabled,
                              },
                            ),
                            icon: Icon(
                              filter.filterEnabled
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: filter.filterEnabled
                                  ? Theme.of(context)
                                      .buttonTheme
                                      .colorScheme!
                                      .primary
                                  : CupertinoColors.destructiveRed,
                            ),
                          ),
                          child: Column(
                            children: filter.filterSettings.entries
                                .map(
                                  (filterSetting) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: DynamicInput(
                                      label: filterSetting.key,
                                      value: filterSetting.value,
                                      onUpdate: (updatedValue) {
                                        NetworkHelper.makeRequest(
                                          GetIt.instance<NetworkStore>()
                                              .activeSession!
                                              .socket,
                                          RequestType.SetSourceFilterSettings,
                                          {
                                            'sourceName': sceneItem.sourceName,
                                            'filterName': filter.filterName,
                                            'filterSettings': {}
                                              ..addAll(filter.filterSettings)
                                              ..update(filterSetting.key,
                                                  (value) => updatedValue),
                                          },
                                        );
                                      },
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
        );
      },
    );
  }
}
