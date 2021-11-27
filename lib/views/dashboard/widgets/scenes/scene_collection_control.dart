import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../shared/overlay/base_progress_indicator.dart';
import '../../../../stores/shared/network.dart';
import '../../../../stores/views/dashboard.dart';
import '../../../../types/enums/request_type.dart';
import '../../../../utils/network_helper.dart';
import '../../../../utils/overlay_handler.dart';

class SceneCollectionControl extends StatelessWidget {
  const SceneCollectionControl({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    return Align(
      alignment: Alignment.centerRight,
      child: Observer(
        builder: (_) => DropdownButton<String>(
          value: dashboardStore.currentSceneCollectionName,
          isDense: true,
          onChanged: (sceneCollectionName) {
            OverlayHandler.showStatusOverlay(
              showDuration: const Duration(seconds: 10),
              context: context,
              content: BaseProgressIndicator(
                text: 'Switching...',
              ),
            );
            dashboardStore.handleRequestsEvents = false;
            NetworkHelper.makeRequest(
              GetIt.instance<NetworkStore>().activeSession!.socket,
              RequestType.SetCurrentSceneCollection,
              {'sc-name': sceneCollectionName},
            );
          },
          items: dashboardStore.sceneCollections
                  ?.map(
                    (sceneCollection) => DropdownMenuItem(
                      value: sceneCollection.scName,
                      child: Text(sceneCollection.scName),
                    ),
                  )
                  .toList() ??
              [],
        ),
      ),
    );
  }
}
