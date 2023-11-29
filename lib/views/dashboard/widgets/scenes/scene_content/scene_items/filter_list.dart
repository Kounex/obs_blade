import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/general/base/divider.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/classes/api/scene_item.dart';
import 'package:obs_blade/types/enums/request_type.dart';
import 'package:obs_blade/utils/network_helper.dart';

class FilterList extends StatelessWidget {
  final SceneItem sceneItem;

  const FilterList({
    super.key,
    required this.sceneItem,
  });

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    return Observer(builder: (context) {
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
      return Padding(
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
            Expanded(
              child: Scrollbar(
                child: ListView.builder(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.paddingOf(context).bottom + 12.0,
                  ),
                  itemCount: sceneItem.filters?.length ?? 0,
                  itemBuilder: (context, index) => ListTile(
                    contentPadding: const EdgeInsets.all(0),
                    title: Text(sceneItem.filters![index].filterName),
                    trailing: IconButton(
                      onPressed: () => NetworkHelper.makeRequest(
                        GetIt.instance<NetworkStore>().activeSession!.socket,
                        RequestType.SetSourceFilterEnabled,
                        {
                          'sourceName': sceneItem.sourceName,
                          'filterName': sceneItem.filters![index].filterName,
                          'filterEnabled':
                              !sceneItem.filters![index].filterEnabled,
                        },
                      ),
                      icon: Icon(
                        sceneItem.filters![index].filterEnabled
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: sceneItem.filters![index].filterEnabled
                            ? Theme.of(context).buttonTheme.colorScheme!.primary
                            : CupertinoColors.destructiveRed,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
