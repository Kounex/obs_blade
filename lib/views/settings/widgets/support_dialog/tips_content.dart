import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:obs_blade/models/purchased_tip.dart';
import 'package:obs_blade/shared/general/hive_builder.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';

import 'donate_button.dart';

class TipsContent extends StatelessWidget {
  final List<ProductDetails> tipsDetails;
  const TipsContent({
    Key? key,
    required this.tipsDetails,
  }) : super(key: key);

  String _sumTipped(Iterable<PurchasedTip> tips) {
    if (tips.isNotEmpty) {
      bool startsWithCurrencySymbol =
          tips.first.price.startsWith(tips.first.currencySymbol);
      double sumTips = double.parse(tips
          .fold<double>(
              0.0,
              (sum, tip) => sum += double.parse(
                  tip.price.replaceAll(tip.currencySymbol, '').trim()))
          .toStringAsFixed(2));

      String sumTipsFormatted =
          (sumTips.toInt().toDouble() == sumTips ? sumTips.toInt() : sumTips)
              .toString();

      String possibleGap = tips.first.price.contains(' ') ? ' ' : '';

      return (startsWithCurrencySymbol
              ? tips.first.currencySymbol
              : sumTipsFormatted) +
          possibleGap +
          (startsWithCurrencySymbol
              ? sumTipsFormatted
              : tips.first.currencySymbol);
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...this
            .tipsDetails
            .map(
              (tip) => DonateButton(
                text: tip.title.isNotEmpty
                    ? tip.title
                    : '${(tip.rawPrice).toInt()} Energy Drink${((tip.rawPrice).toInt() > 1 ? "s" : "")}',
                price: tip.price,
                purchaseParam: PurchaseParam(productDetails: tip),
              ),
            )
            .toList(),
        HiveBuilder<PurchasedTip>(
          hiveKey: HiveKeys.PurchasedTip,
          builder: (context, purchasedTipBox, child) {
            if (purchasedTipBox.values.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                    'You tipped ${_sumTipped(purchasedTipBox.values)} so far\nYou are awesome :)'),
              );
            }
            return Container();
          },
        ),
      ],
    );
  }
}
