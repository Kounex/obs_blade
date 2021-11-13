import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:obs_blade/shared/general/base/button.dart';
import 'package:obs_blade/stores/shared/purchases.dart';
import 'package:obs_blade/stores/shared/tabs.dart';
import 'package:obs_blade/utils/routing_helper.dart';

import 'donate_button.dart';

class BlacksmithContent extends StatelessWidget {
  final List<ProductDetails> blacksmithDetails;

  const BlacksmithContent({
    Key? key,
    required this.blacksmithDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    PurchasesStore purchasesStore = GetIt.instance<PurchasesStore>();

    return Observer(
      builder: (_) {
        if (!purchasesStore.purchases
            .any((purchase) => purchase.productID == 'blacksmith')) {
          return DonateButton(
            price: this.blacksmithDetails[0].price,
            purchaseParam:
                PurchaseParam(productDetails: this.blacksmithDetails[0]),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BaseButton(
              text: 'Forge Theme',
              secondary: true,
              onPressed: () {
                Navigator.of(context).pop(true);
                TabsStore tabsStore = GetIt.instance<TabsStore>();

                if (tabsStore.activeRoutePerNavigator[Tabs.Settings] !=
                    SettingsTabRoutingKeys.CustomTheme.route) {
                  Future.delayed(
                    const Duration(milliseconds: 500),
                    () => tabsStore.navigatorKeys[Tabs.Settings]?.currentState
                        ?.pushNamed(
                      SettingsTabRoutingKeys.CustomTheme.route,
                      arguments: {'blacksmith': true},
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
