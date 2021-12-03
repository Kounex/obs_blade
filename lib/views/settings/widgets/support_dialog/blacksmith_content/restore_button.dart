import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:obs_blade/shared/dialogs/info.dart';
import 'package:obs_blade/shared/general/hive_builder.dart';
import 'package:obs_blade/shared/general/themed/cupertino_button.dart';
import 'package:obs_blade/shared/overlay/base_progress_indicator.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:obs_blade/utils/overlay_handler.dart';

class RestoreButton extends StatelessWidget {
  const RestoreButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [SettingsKeys.BoughtBlacksmith],
      builder: (context, settingsBox, child) => ThemedCupertinoButton(
        text: 'Restore',
        onPressed: !settingsBox.get(
          SettingsKeys.BoughtBlacksmith.name,
          defaultValue: false,
        )
            ? () {
                /// Initiate to restore all (currently only Blacksmith) non-consumable purchases.
                /// Show an overlay to wait for the purchase stream in purchase_base to receive
                /// the restore status (if successful) where we will close the overlay and show
                /// the info dialog which says that it worked!
                InAppPurchase.instance.restorePurchases();
                OverlayHandler.showStatusOverlay(
                  context: context,
                  showDuration: const Duration(seconds: 5),
                  content: BaseProgressIndicator(
                    text: 'Trying to restore...',
                  ),
                );

                /// After a fixed amount of time we check if the user got the "BoughtBlacksmith"
                /// status in Hive which would be there if the restoration worked out earlier.
                /// If not, we will close the overlay and show a unsuccessfull info dialog!
                Future.delayed(
                  const Duration(seconds: 5),
                  () {
                    if (!settingsBox.get(SettingsKeys.BoughtBlacksmith.name,
                        defaultValue: false)) {
                      OverlayHandler.closeAnyOverlay(immediately: false);
                      ModalHandler.showBaseDialog(
                        context: context,
                        dialogWidget: const InfoDialog(
                          body:
                              'It was not possible to restore Blacksmith. Make sure you have a working internet connection and you actually bought it before!\n\nYou can try to buy it again - it won\'t be possible if you bought it with your current App Store account.\n\nContact me if you can\'t find a solution!',
                        ),
                      );
                    }
                  },
                );
              }
            : null,
      ),
    );
  }
}
