import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../../stores/shared/network.dart';
import '../../../../../stores/views/dashboard.dart';
import '../../../../../types/classes/api/scene.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/request_type.dart';
import '../../../../../types/enums/settings_keys.dart';
import '../../../../../utils/network_helper.dart';

class SceneButton extends StatelessWidget {
  final Scene scene;
  final bool visible;
  final VoidCallback onVisibilityTap;

  final double height;
  final double width;

  const SceneButton({
    required this.scene,
    required this.visible,
    required this.onVisibilityTap,
    this.height = 100.0,
    this.width = 100.0,
  });

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = context.read<DashboardStore>();

    return ValueListenableBuilder(
      valueListenable: Hive.box(HiveKeys.Settings.name).listenable(keys: [
        SettingsKeys.ExposeStudioControls.name,
      ]),
      builder: (context, Box settingsBox, child) => Observer(
        builder: (_) => GestureDetector(
          onTap: () {
            if (dashboardStore.editSceneVisibility) {
              this.onVisibilityTap();
            } else {
              if (settingsBox.get(SettingsKeys.ExposeStudioControls.name,
                      defaultValue: false) &&
                  dashboardStore.studioMode) {
                NetworkHelper.makeRequest(
                    context.read<NetworkStore>().activeSession!.socket,
                    RequestType.SetPreviewScene,
                    {'scene-name': scene.name});
              } else {
                NetworkHelper.makeRequest(
                    context.read<NetworkStore>().activeSession!.socket,
                    RequestType.SetCurrentScene,
                    {'scene-name': scene.name});
              }
            }
          },
          child: Stack(
            children: [
              AnimatedContainer(
                duration: Duration(
                    milliseconds:
                        dashboardStore.sceneTransitionDurationMS != null &&
                                dashboardStore.sceneTransitionDurationMS! >= 0
                            ? dashboardStore.sceneTransitionDurationMS!
                            : 0),
                alignment: Alignment.center,
                height: this.height,
                width: this.width,
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
                height: this.height,
                width: this.width,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: (settingsBox.get(
                                    SettingsKeys.ExposeStudioControls.name,
                                    defaultValue: false) &&
                                dashboardStore.studioMode
                            ? dashboardStore.studioModePreviewSceneName ==
                                scene.name
                            : dashboardStore.activeSceneName == scene.name)
                        ? Theme.of(context).accentColor
                        : Theme.of(context).cardColor,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              if (dashboardStore.editSceneVisibility)
                Positioned(
                  top: 1.0,
                  right: 1.0,
                  child: Container(
                    height: 32.0,
                    width: 32.0,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      // hiddenScene != null
                      //     ? CupertinoColors.destructiveRed
                      //     : Theme.of(context).buttonColor,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(12.0),
                        bottomLeft: Radius.circular(12.0),
                      ),
                    ),
                    child: Icon(
                      !this.visible ? Icons.visibility_off : Icons.visibility,
                      color: !this.visible
                          ? CupertinoColors.destructiveRed
                          : Theme.of(context).buttonColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
