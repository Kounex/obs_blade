import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:obs_station/stores/views/dashboard.dart';
import 'package:provider/provider.dart';

class SceneItems extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = Provider.of<DashboardStore>(context);

    return Observer(builder: (_) {
      return Column(
        children: dashboardStore.currentSceneItems != null
            ? dashboardStore.currentSceneItems
                .map(
                  (sceneItem) => Text(
                    sceneItem.name,
                  ),
                )
                .toList()
            : [Text('No Scene Items available')],
      );
    });
  }
}
