import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:obs_blade/shared/dialogs/confirmation.dart';
import 'package:obs_blade/shared/general/base/button.dart';
import 'package:obs_blade/stores/shared/purchases.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/modal_handler.dart';

class DonateButton extends StatelessWidget {
  final String? text;
  final String price;

  final PurchaseParam purchaseParam;

  const DonateButton({
    Key? key,
    this.text,
    required this.price,
    required this.purchaseParam,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget purchaseButton = BaseButton(
      padding: const EdgeInsets.all(0.0),
      onPressed: () => this.purchaseParam.productDetails.id != 'blacksmith' &&
              !GetIt.instance<PurchasesStore>()
                  .purchases
                  .any((purchase) => purchase.productID == 'blacksmith') &&
              !Hive.box(HiveKeys.Settings.name).get(
                SettingsKeys.DontShowConsiderBlacksmithBeforeTip.name,
                defaultValue: false,
              )
          ? ModalHandler.showBaseDialog(
              context: context,
              dialogWidget: ConfirmationDialog(
                title: 'Before you leave a tip...',
                body:
                    'You haven\'t purchased Blacksmith yet and you are trying to leave me a tip - you won\'t get anything from tipping me but Blacksmith gives you some customisation at least so that might make more sense for you!\n\nJust consider this before you actually leave a tip! :)',
                noText: 'Cancel',
                okText: 'Leave Tip',
                enableDontShowAgainOption: true,
                onOk: (checked) {
                  Hive.box(HiveKeys.Settings.name).put(
                    SettingsKeys.DontShowConsiderBlacksmithBeforeTip.name,
                    checked,
                  );
                  InAppPurchase.instance
                      .buyNonConsumable(purchaseParam: this.purchaseParam);
                },
              ),
            )
          : InAppPurchase.instance
              .buyNonConsumable(purchaseParam: this.purchaseParam),
      child: Text(this.price),
    );

    if (this.text == null) return purchaseButton;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          this.text!,
          style: Theme.of(context).textTheme.bodyText2,
        ),
        purchaseButton,
      ],
    );
  }
}
