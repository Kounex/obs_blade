import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:obs_blade/shared/general/base/button.dart';
import 'package:obs_blade/shared/general/base/card.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/enums/request_type.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:obs_blade/utils/network_helper.dart';
import 'package:obs_blade/views/dashboard/widgets/scenes/hotkeys/hotkey_list.dart';

import '../../../../../shared/dialogs/confirmation.dart';
import '../../../../../shared/general/hive_builder.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';

class Hotkeys extends StatelessWidget {
  const Hotkeys({super.key});

  @override
  Widget build(BuildContext context) {
    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [SettingsKeys.ExposeHotkeys],
      builder: (context, settingsBox, child) => settingsBox
              .get(SettingsKeys.ExposeHotkeys.name, defaultValue: false)
          ? BaseCard(
              bottomPadding: 0,
              paddingChild: const EdgeInsets.symmetric(horizontal: 18.0) +
                  const EdgeInsets.symmetric(vertical: 12.0),
              child: SizedBox(
                width: double.infinity,
                child: BaseButton(
                  onPressed: () {
                    void onHotkeys() {
                      GetIt.instance<DashboardStore>().hotkeys = null;
                      NetworkHelper.makeRequest(
                        GetIt.instance<NetworkStore>().activeSession!.socket,
                        RequestType.GetHotkeyList,
                      );
                      ModalHandler.showBaseCupertinoBottomSheet(
                        context: context,
                        modalWidgetBuilder: (context, controller) => HotkeyList(
                          controller: controller,
                        ),
                      );
                    }

                    !Hive.box<dynamic>(HiveKeys.Settings.name).get(
                            SettingsKeys
                                .DontShowHotkeysTechnicalPreviewWarning.name,
                            defaultValue: false)
                        ? ModalHandler.showBaseDialog(
                            context: context,
                            dialogWidget: ConfirmationDialog(
                              enableDontShowAgainOption: true,
                              title: 'Technical Preview',
                              body:
                                  'The hotkey capabilities of the WebSocket API are currently very limited and therefore this feature is currently in technical preview. Since it might still be useful for some, even in this condition, I added the basic functionality. It is expected to not work properly. I will update this feature once it is more mature!',
                              noText: 'Cancel',
                              okText: 'Ok',
                              onOk: (checked) {
                                Hive.box<dynamic>(HiveKeys.Settings.name).put(
                                    SettingsKeys
                                        .DontShowHotkeysTechnicalPreviewWarning
                                        .name,
                                    checked);
                                onHotkeys();
                              },
                            ),
                          )
                        : onHotkeys();
                  },
                  icon: const Icon(
                    CupertinoIcons.rectangle_grid_3x2_fill,
                  ),
                  text: 'Hotkeys',
                ),
              ),
            )
          : const SizedBox(),
    );
  }
}
