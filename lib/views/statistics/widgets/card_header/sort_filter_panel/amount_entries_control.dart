import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../shared/design/design.dart';
import '../../../../../stores/views/statistics.dart';

class AmountEntriesControl extends StatelessWidget {
  const AmountEntriesControl({super.key});

  @override
  Widget build(BuildContext context) {
    StatisticsStore statisticsStore = GetIt.instance<StatisticsStore>();

    final AppTextColors textColors = Theme.of(
      context,
    ).extension<AppTextColors>()!;
    final bool darkSurface =
        Theme.of(context).cardColor.computeLuminance() <= 0.2;

    /// Neutral segment chrome (mirrors the connect-method segment in
    /// [SwitcherCard]): 6% track, 13% thumb, selection carried by the
    /// thumb fill + label emphasis alone
    final Color segBackground = (darkSurface ? Colors.white : Colors.black)
        .withValues(alpha: 0.06);
    final Color segThumb = darkSurface
        ? Colors.white.withValues(alpha: 0.13)
        : Colors.white;

    return Observer(
      builder: (context) => SizedBox(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl<AmountStatisticEntries>(
          groupValue: statisticsStore.amountStatisticEntries,
          padding: const EdgeInsets.all(0),
          backgroundColor: segBackground,
          thumbColor: segThumb,
          children: Map.fromEntries(
            AmountStatisticEntries.values.map(
              (amount) => MapEntry(
                amount,
                Text(
                  amount.number.toString(),
                  style: TextStyle(
                    color: statisticsStore.amountStatisticEntries == amount
                        ? textColors.textPrimary
                        : textColors.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
          onValueChanged: (amountEntries) =>
              statisticsStore.setAmountStatisticEntries(amountEntries!),
        ),
      ),
    );
  }
}
