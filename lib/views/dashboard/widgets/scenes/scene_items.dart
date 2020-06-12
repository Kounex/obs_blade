import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:obs_station/stores/views/dashboard.dart';
import 'package:provider/provider.dart';

class SceneItems extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = Provider.of<DashboardStore>(context);

    return Observer(builder: (_) {
      dashboardStore.currentSceneItems
          ?.forEach((element) => print(element.type));
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ...dashboardStore.currentSceneItems != null
              ? dashboardStore.currentSceneItems.map(
                  (sceneItem) => ListTile(
                    leading: Icon(Icons.volume_off),
                    title: Text(
                      sceneItem.name,
                    ),
                  ),
                )
              : [Text('No Scene Items available')]
        ],
      );
    });
  }
}
