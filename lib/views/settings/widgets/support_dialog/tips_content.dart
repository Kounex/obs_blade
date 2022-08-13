import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:obs_blade/shared/general/base/divider.dart';

import '../../../../models/purchased_tip.dart';
import '../../../../shared/general/hive_builder.dart';
import '../../../../types/enums/hive_keys.dart';
import '../../../../types/extensions/list.dart';
import 'donate_button.dart';

List<String> kTipAwesomeness = [
  'Nice',
  'Awesome',
  'Incredible',
  'Unbelieveable',
  'You-Gotta-Be-Kidding-Me'
];

class TipsContent extends StatelessWidget {
  final List<ProductDetails>? tipsDetails;

  /// Since tips are going to be pre-rendered while the actual
  /// tip data is being fetched from the store, this is the amount
  /// of tips I assume are going to be available and render those
  final int amountTips;

  const TipsContent({
    Key? key,
    required this.tipsDetails,
    this.amountTips = 3,
  }) : super(key: key);

  String _sumTipped(Iterable<PurchasedTip> tips) {
    if (tips.isNotEmpty) {
      bool startsWithCurrencySymbol =
          tips.first.price.startsWith(tips.first.currencySymbol);
      double sumTips = double.parse(tips
          .fold<double>(
              0.0,
              (sum, tip) => sum += double.parse(tip.price
                  .replaceAll(tip.currencySymbol, '')
                  .replaceAll(',', '.')
                  .trim()))
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
        const Text(
            'If you enjoy OBS Blade and want to support the development, leaving a tip would mean a lot to me!'),
        // const SizedBox(height: 12.0),
        const BaseDivider(
          height: 24.0,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Column(
              children: [
                if (this.tipsDetails == null || this.tipsDetails!.isEmpty)
                  ...kTipAwesomeness.take(this.amountTips).map(
                        (tipAwesomeness) => DonateButton(
                          text: '$tipAwesomeness Tip',
                          errorText: this.tipsDetails != null
                              ? 'Could not retrieve App Store information! Please check your internet connection and try again. If this problem persists, please reach out to me, thanks!'
                              : null,
                        ),
                      ),
                if (this.tipsDetails != null && this.tipsDetails!.isNotEmpty)
                  ...this
                      .tipsDetails!
                      .take(kTipAwesomeness.length)
                      .mapIndexed(
                        (tip, index) => DonateButton(
                          text: '${kTipAwesomeness[index]} Tip',
                          price: tip.price,
                          purchaseParam: PurchaseParam(productDetails: tip),
                        ),
                      )
                      .toList(),
              ],
            ),
          ),
        ),
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
