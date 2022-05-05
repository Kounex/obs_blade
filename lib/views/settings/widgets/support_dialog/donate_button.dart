import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../../shared/dialogs/confirmation.dart';
import '../../../../shared/dialogs/info.dart';
import '../../../../shared/general/base/button.dart';
import '../../../../types/enums/hive_keys.dart';
import '../../../../types/enums/settings_keys.dart';
import '../../../../utils/modal_handler.dart';

class DonateButton extends StatelessWidget {
  final String? text;
  final String? price;
  final String? errorText;

  final PurchaseParam? purchaseParam;

  const DonateButton({
    Key? key,
    this.text,
    this.price,
    this.errorText,
    this.purchaseParam,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget purchaseButton = BaseButton(
      shrinkWidth: true,
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      onPressed: this.purchaseParam != null
          ? () => this.purchaseParam!.productDetails.id.contains('tip') &&
                  !Hive.box(HiveKeys.Settings.name).get(
                    SettingsKeys.BoughtBlacksmith.name,
                    defaultValue: false,
                  ) &&
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
                          .buyConsumable(purchaseParam: this.purchaseParam!);
                    },
                  ),
                )
              : this.purchaseParam!.productDetails.id.contains('tip')
                  ? InAppPurchase.instance
                      .buyConsumable(purchaseParam: this.purchaseParam!)
                  : InAppPurchase.instance
                      .buyNonConsumable(purchaseParam: this.purchaseParam!)
          : this.errorText != null
              ? () => ModalHandler.showBaseDialog(
                  context: context,
                  dialogWidget: InfoDialog(body: this.errorText!))
              : null,
      child: Text(this.price ?? '-'),
    );

    if (this.text == null) return purchaseButton;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            this.text!,
            textAlign: TextAlign.left,
          ),
        ),
        purchaseButton,
      ],
    );
  }
}
