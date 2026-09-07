import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:obs_blade/shared/overlay/base_progress_indicator.dart';

import '../../../../shared/dialogs/info.dart';
import '../../../../shared/general/base/button.dart';
import '../../../../utils/modal_handler.dart';

class DonateButton extends StatelessWidget {
  final String? text;
  final String? price;
  final String? errorText;

  final PurchaseParam? purchaseParam;

  const DonateButton({
    super.key,
    this.text,
    this.price,
    this.errorText,
    this.purchaseParam,
  });

  @override
  Widget build(BuildContext context) {
    Widget purchaseButton = BaseButton(
      shrinkWidth: true,
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      onPressed: this.purchaseParam != null
          ? () => this.purchaseParam!.productDetails.id.contains('tip')
              ? InAppPurchase.instance
                  .buyConsumable(purchaseParam: this.purchaseParam!)
              : InAppPurchase.instance
                  .buyNonConsumable(purchaseParam: this.purchaseParam!)
          : this.errorText != null
              ? () => ModalHandler.showBaseDialog(
                  context: context,
                  barrierDismissible: true,
                  dialogWidget: InfoDialog(body: this.errorText!))
              : null,
      child: this.price != null || this.errorText != null
          ? Text(
              this.price ?? '-',
              style: const TextStyle(
                fontFeatures: [
                  FontFeature.tabularFigures(),
                ],
              ),
            )
          : BaseProgressIndicator(size: 18.0),
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
