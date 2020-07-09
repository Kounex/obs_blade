import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/classes/api/scene.dart';
import 'package:obs_blade/types/enums/request_type.dart';
import 'package:obs_blade/utils/network_helper.dart';
import 'package:provider/provider.dart';

class SceneButton extends StatelessWidget {
  final Scene scene;
  const SceneButton({@required this.scene});

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = Provider.of<DashboardStore>(context);

    return Observer(
      builder: (_) => GestureDetector(
        onTap: () => NetworkHelper.makeRequest(
            dashboardStore.activeSession.socket.sink,
            RequestType.SetCurrentScene,
            {'scene-name': scene.name}),
        child: Stack(
          children: [
            AnimatedContainer(
              duration: Duration(
                  milliseconds:
                      dashboardStore.sceneTransitionDurationMS != null &&
                              dashboardStore.sceneTransitionDurationMS >= 0
                          ? dashboardStore.sceneTransitionDurationMS
                          : 0),
              alignment: Alignment.center,
              height: 100.0,
              width: 100.0,
              decoration: BoxDecoration(
                color: dashboardStore.activeSceneName == scene.name
                    ? Theme.of(context).accentColor
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  scene.name,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            AnimatedContainer(
              duration: Duration(milliseconds: 50),
              height: 100.0,
              width: 100.0,
              decoration: BoxDecoration(
                border: Border.all(
                  color: dashboardStore.activeSceneName == scene.name
                      ? Theme.of(context).accentColor
                      : Theme.of(context).cardColor,
                ),
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
