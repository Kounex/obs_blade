import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/types/enums/request_type.dart';
import 'package:obs_blade/utils/network_helper.dart';

import '../../../../stores/views/dashboard.dart';

class SceneCollectionControl extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    return Align(
      alignment: Alignment.centerRight,
      child: Observer(
        builder: (_) => DropdownButton<String>(
          value: dashboardStore.currentSceneCollectionName,
          isDense: true,
          onChanged: (sceneCollectionName) => NetworkHelper.makeRequest(
            GetIt.instance<NetworkStore>().activeSession!.socket,
            RequestType.SetCurrentSceneCollection,
            {'sc-name': sceneCollectionName},
          ),
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
