import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:obs_station/stores/shared/network.dart';
import 'package:obs_station/stores/views/dashboard.dart';
import 'package:obs_station/types/enums/request_type.dart';
import 'package:obs_station/utils/network_helper.dart';
import 'package:provider/provider.dart';

class SceneItems extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = Provider.of<DashboardStore>(context);

    return Observer(builder: (_) {
      dashboardStore.currentSceneItems
          ?.forEach((element) => print(element.type));
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ...dashboardStore.currentSceneItems != null
              ? dashboardStore.currentSceneItems.map(
                  (sceneItem) => ListTile(
                    leading: Icon(Icons.filter),
                    title: Text(
                      sceneItem.name,
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        sceneItem.render
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: sceneItem.render ? Colors.white : Colors.red,
                      ),
                      onPressed: () => NetworkHelper.makeRequest(
                          dashboardStore.activeSession.socket.sink,
                          RequestType.SetSceneItemProperties, {
                        'item': sceneItem.name,
                        'visible': !sceneItem.render
                      }),
                    ),
                  ),
                )
              : [Text('No Scene Items available')]
        ],
      );
    });
  }
}
