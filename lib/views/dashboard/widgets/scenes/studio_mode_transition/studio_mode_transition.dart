import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/general/base/base_button.dart';

import '../../../../../shared/general/hive_builder.dart';
import '../../../../../stores/shared/network.dart';
import '../../../../../stores/views/dashboard.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/request_type.dart';
import '../../../../../types/enums/settings_keys.dart';
import '../../../../../utils/network_helper.dart';
import 'transition.dart';

class StudioModeTransition extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: [SettingsKeys.ExposeStudioControls],
      builder: (context, settingsBox, child) => Observer(builder: (_) {
        dashboardStore.studioMode;
        return Column(
          children: [
            if (settingsBox.get(SettingsKeys.ExposeStudioControls.name,
                    defaultValue: false) &&
                dashboardStore.studioMode)
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: SizedBox(
                    width: 128.0,
                    child: BaseButton(
                      text: 'Transition',
                      secondary: true,
                      onPressed: () => NetworkHelper.makeRequest(
                        GetIt.instance<NetworkStore>().activeSession!.socket,
                        RequestType.TransitionToProgram,
                      ),
                    ),
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  settingsBox.get(SettingsKeys.ExposeStudioControls.name,
                          defaultValue: false)
                      ? Padding(
                          padding: const EdgeInsets.only(right: 24.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: dashboardStore.studioMode,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                onChanged: (studioMode) =>
                                    NetworkHelper.makeRequest(
                                  GetIt.instance<NetworkStore>()
                                      .activeSession!
                                      .socket,
                                  RequestType.ToggleStudioMode,
                                ),
                              ),
                              Text('Studio Mode'),
                            ],
                          ),
                        )
                      : Container(),
                  Flexible(
                    child: Transition(),
                  ),
                ],
              ),
            )
          ],
        );
      }),
    );
  }
}
