import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:obs_station/stores/views/dashboard.dart';
import 'package:obs_station/types/enums/request_type.dart';
import 'package:obs_station/utils/network_helper.dart';
import 'package:provider/provider.dart';

class Scenes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = Provider.of<DashboardStore>(context);

    return Observer(
      builder: (_) => Padding(
        padding: const EdgeInsets.only(top: 24.0),
        child: Center(
          child: Wrap(
            runSpacing: 24.0,
            spacing: 24.0,
            children: dashboardStore.scenes != null &&
                    dashboardStore.scenes.length > 0
                ? dashboardStore.scenes
                    .map(
                      (scene) => GestureDetector(
                        onTap: () => NetworkHelper.makeRequest(
                            dashboardStore.activeSession.socket.sink,
                            RequestType.SetCurrentScene,
                            {'scene-name': scene.name}),
                        child: Container(
                          alignment: Alignment.center,
                          height: 100.0,
                          width: 100.0,
                          decoration: BoxDecoration(
                            color: dashboardStore.activeSceneName == scene.name
                                ? Theme.of(context).accentColor
                                : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Text(scene.name),
                        ),
                      ),
                    )
                    .toList()
                : [Text('nothing here')],
          ),
        ),
      ),
    );
  }
}
