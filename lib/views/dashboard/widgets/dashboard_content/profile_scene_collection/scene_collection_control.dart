import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../shared/general/base/dropdown.dart';
import '../../../../../stores/views/dashboard.dart';
import '../../../../../types/enums/request_type.dart';

class SceneCollectionControl extends StatelessWidget {
  const SceneCollectionControl({super.key});

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    return Observer(
      builder: (context) {
        return BaseDropdown<String>(
          value:
              dashboardStore.sceneCollections != null &&
                  dashboardStore.sceneCollections!.contains(
                    dashboardStore.currentSceneCollectionName,
                  )
              ? dashboardStore.currentSceneCollectionName
              : null,
          items:
              dashboardStore.sceneCollections
                  ?.map(
                    (sceneCollection) => BaseDropdownItem(
                      value: sceneCollection,
                      text: sceneCollection,
                    ),
                  )
                  .toList() ??
              [],
          label: 'Scene Collection',
          onChanged: (sceneCollection) {
            if (sceneCollection != dashboardStore.currentSceneCollectionName) {
              dashboardStore.sendMutation(
                RequestType.SetCurrentSceneCollection,
                fields: {'sceneCollectionName': sceneCollection},
                label: 'Scene collection switch',
              );
            }
          },
        );
      },
    );
  }
}
