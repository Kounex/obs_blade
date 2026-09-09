import 'package:flutter/cupertino.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/hive_builder.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';

import '../../../../../shared/general/base/button.dart';
import '../../../../../stores/shared/network.dart';
import '../../../../../types/enums/request_type.dart';
import '../../../../../utils/network_helper.dart';

class StudioModeTransitionButton extends StatelessWidget {
  const StudioModeTransitionButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [
        SettingsKeys.ExposeStudioControls,
      ],
      builder: (context, settingsBox, child) {
        return Observer(
          builder: (context) {
            /// Read outside the `&&` below: when the Hive flag short-circuits,
            /// the observable would not be tracked in this pass and MobX
            /// would log a "no observables" warning for this [Observer]
            final bool studioMode = dashboardStore.studioMode;

            return AnimatedSwitcher(
              duration: AppMotion.medium,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: AppMotion.standard,
                  reverseCurve: AppMotion.exit,
                ),
                child: SizeTransition(
                  sizeFactor: CurvedAnimation(
                    parent: animation,
                    curve: AppMotion.standard,
                    reverseCurve: AppMotion.exit,
                  ),
                  child: child,
                ),
              ),
              child: (settingsBox.get(SettingsKeys.ExposeStudioControls.name,
                          defaultValue: false) &&
                      studioMode)
                  ? Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 128.0,
                        child: BaseButton(
                          text: 'Transition',
                          secondary: true,
                          onPressed: () {
                            dashboardStore.setActiveSceneName(
                                dashboardStore.studioModePreviewSceneName!);
                            NetworkHelper.makeRequest(
                              GetIt.instance<NetworkStore>()
                                  .activeSession!
                                  .socket,
                              RequestType.SetCurrentProgramScene,
                              {
                                'sceneName':
                                    dashboardStore.studioModePreviewSceneName
                              },
                            );
                          },
                        ),
                      ),
                    )
                  : const SizedBox(),
            );
          },
        );
      },
    );
  }
}
