import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:obs_blade/shared/general/base/button.dart';
import 'package:obs_blade/shared/general/base/divider.dart';

import '../../../../models/purchased_tip.dart';
import '../../../../shared/design/design.dart';
import '../../../../shared/general/hive_builder.dart';
import '../../../../types/enums/hive_keys.dart';
import '../../../../types/extensions/list.dart';
import 'donate_button.dart';
import 'support_skeleton.dart';

List<String> kTipAwesomeness = [
  'Nice',
  'Awesome',
  'Incredible',
  'Unbelieveable',
  'You-Gotta-Be-Kidding-Me',
];

class TipsContent extends StatelessWidget {
  final List<ProductDetails>? tipsDetails;

  /// Re-triggers the store fetch (support dialog owns the future) - wired
  /// to the retry action of the inline store-error state
  final VoidCallback? onRetry;

  const TipsContent({super.key, required this.tipsDetails, this.onRetry});

  /// The tipped total split into its parts so the amount can count up on
  /// its own ([CountUpText]) while the currency symbol keeps its
  /// store-specific placement (leading/trailing, optional gap)
  (String, String, bool, String) _sumParts(Iterable<PurchasedTip> tips) {
    bool startsWithCurrencySymbol = tips.first.price.startsWith(
      tips.first.currencySymbol,
    );
    double sumTips = double.parse(
      tips
          .fold<double>(
            0.0,
            (sum, tip) => sum += double.parse(
              tip.price
                  .replaceAll(tip.currencySymbol, '')
                  .replaceAll(',', '.')
                  .trim(),
            ),
          )
          .toStringAsFixed(2),
    );

    String sumTipsFormatted =
        (sumTips.toInt().toDouble() == sumTips ? sumTips.toInt() : sumTips)
            .toString();

    String possibleGap = tips.first.price.contains(' ') ? ' ' : '';

    return (
      sumTipsFormatted,
      tips.first.currencySymbol,
      startsWithCurrencySymbol,
      possibleGap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoading = this.tipsDetails == null;

    return Column(
      children: [
        const Text(
          'If you enjoy OBS Blade and want to support the development, leaving a tip would mean a lot to me!',
        ),
        // const SizedBox(height: 12.0),
        const BaseDivider(height: 24.0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: AnimatedSwitcher(
            duration: AppMotion.medium,
            child: isLoading
                /// Skeleton placeholder rows while the store answers -
                /// replaced by the priced (or error) buttons once done
                ? const SupportSkeleton(key: ValueKey('loading'), rows: 3)
                : this.tipsDetails!.isEmpty
                /// Store unreachable / no products: inline error instead of
                /// tappable placeholder price rows - retry re-runs the fetch
                ? Column(
                    key: const ValueKey('error'),
                    children: [
                      Icon(
                        CupertinoIcons.exclamationmark_circle,
                        size: 32.0,
                        color: Theme.of(
                          context,
                        ).extension<AppStatusColors>()!.destructiveText,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Could not retrieve App Store information! Please check your internet connection and try again. If this problem persists, please reach out to me, thanks!',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      BaseButton(
                        text: 'Try Again',
                        secondary: true,
                        shrinkWidth: true,
                        onPressed: this.onRetry,
                      ),
                    ],
                  )
                : Column(
                    key: const ValueKey('loaded'),
                    children: [
                      ...(this.tipsDetails!
                            ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice)))
                          .mapIndexed(
                            (tip, index) => DonateButton(
                              text: '${kTipAwesomeness[index]} Tip',
                              price: tip.price,
                              purchaseParam: PurchaseParam(productDetails: tip),
                            ),
                          ),
                    ],
                  ),
          ),
        ),
        HiveBuilder<PurchasedTip>(
          hiveKey: HiveKeys.PurchasedTip,
          builder: (context, purchasedTipBox, child) {
            if (purchasedTipBox.values.isNotEmpty) {
              final (
                String amount,
                String currencySymbol,
                bool symbolFirst,
                String gap,
              ) = _sumParts(
                purchasedTipBox.values,
              );

              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'You tipped '),
                      if (symbolFirst) TextSpan(text: currencySymbol + gap),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: CountUpText(
                          value: amount,
                          style: DefaultTextStyle.of(context).style,
                        ),
                      ),
                      if (!symbolFirst) TextSpan(text: gap + currencySymbol),
                      const TextSpan(text: ' so far\nYou are awesome :)'),
                    ],
                  ),
                ),
              );
            }
            return Container();
          },
        ),
      ],
    );
  }
}
