import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../../../shared/general/base/button.dart';
import '../../../../../shared/general/base/divider.dart';
import '../../../../../shared/general/hive_builder.dart';
import '../../../../../shared/general/themed/rich_text.dart';
import '../../../../../stores/shared/tabs.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';
import '../../../../../utils/modal_handler.dart';
import '../../../../../utils/routing_helper.dart';
import '../donate_button.dart';
import 'restore_button.dart';

class BlacksmithContent extends StatelessWidget {
  final List<ProductDetails>? blacksmithDetails;

  const BlacksmithContent({
    super.key,
    required this.blacksmithDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ThemedRichText(
          textAlign: TextAlign.center,
          textSpans: [
            TextSpan(
              text: 'Become a blacksmith and forge your own OBS Blade',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: BaseDivider(),
              ),
            ),
            TextSpan(
              text:
                  'Blacksmith offers you visual customisation options for this app to make it more personalised! Create your own theme to change the overall look and feel of this app to make it yours!',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 12.0),
        HiveBuilder<dynamic>(
          hiveKey: HiveKeys.Settings,
          rebuildKeys: const [SettingsKeys.BoughtBlacksmith],
          builder: (context, settingsBox, child) {
            if (!settingsBox.get(
              SettingsKeys.BoughtBlacksmith.name,
              defaultValue: false,
            )) {
              if (this.blacksmithDetails != null &&
                  this.blacksmithDetails!.isNotEmpty) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const RestoreButton(),
                    DonateButton(
                      price: this.blacksmithDetails![0].price,
                      purchaseParam: PurchaseParam(
                        productDetails: this.blacksmithDetails![0],
                      ),
                    ),
                  ],
                );
              }
              return DonateButton(
                errorText: this.blacksmithDetails != null &&
                        this.blacksmithDetails!.isEmpty
                    ? 'Could not retrieve App Store information! Please check your internet connection and try again. If this problem persists, please reach out to me, thanks!'
                    : null,
              );
            }
            return BaseButton(
              text: 'Forge Theme',
              secondary: true,
              onPressed: () {
                Navigator.of(context).pop(true);
                TabsStore tabsStore = GetIt.instance<TabsStore>();

                if (tabsStore.activeRoutePerNavigator[Tabs.Settings] !=
                    SettingsTabRoutingKeys.CustomTheme.route) {
                  Future.delayed(
                    ModalHandler.transitionDelayDuration,
                    () => tabsStore.navigatorKeys[Tabs.Settings]?.currentState
                        ?.pushNamed(
                      SettingsTabRoutingKeys.CustomTheme.route,
                      arguments: {'blacksmith': true},
                    ),
                  );
                }
              },
            );
          },
        ),
      ],
    );
  }
}
