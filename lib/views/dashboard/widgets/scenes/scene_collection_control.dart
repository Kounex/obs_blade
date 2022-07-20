import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../shared/general/hive_builder.dart';
import '../../../../shared/overlay/base_progress_indicator.dart';
import '../../../../stores/shared/network.dart';
import '../../../../stores/views/dashboard.dart';
import '../../../../types/enums/hive_keys.dart';
import '../../../../types/enums/request_type.dart';
import '../../../../types/enums/settings_keys.dart';
import '../../../../utils/network_helper.dart';
import '../../../../utils/overlay_handler.dart';

class SceneCollectionControl extends StatelessWidget {
  const SceneCollectionControl({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [SettingsKeys.ExposeSceneCollection],
      builder: (context, settingsBox, child) => settingsBox
              .get(SettingsKeys.ExposeSceneCollection.name, defaultValue: true)
          ? Align(
              alignment: Alignment.centerRight,
              child: Observer(
                builder: (_) => DropdownButton<String>(
                  value: dashboardStore.currentSceneCollectionName,
                  isDense: true,
                  onChanged: (sceneCollectionName) {
                    if (sceneCollectionName !=
                        dashboardStore.currentSceneCollectionName) {
                      OverlayHandler.showStatusOverlay(
                        showDuration: const Duration(seconds: 10),
                        context: context,
                        content: BaseProgressIndicator(
                          text: 'Switching...',
                        ),
                      );
                      NetworkHelper.makeRequest(
                        GetIt.instance<NetworkStore>().activeSession!.socket,
                        RequestType.SetCurrentSceneCollection,
                        {'sceneCollectionName': sceneCollectionName},
                      );
                    }
                  },
                  items: dashboardStore.sceneCollections
                          ?.map(
                            (sceneCollectionName) => DropdownMenuItem(
                              value: sceneCollectionName,
                              child: Text(sceneCollectionName),
                            ),
                          )
                          .toList() ??
                      [],
                ),
              ),
            )
          : Container(),
    );
  }
}
