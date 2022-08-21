import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../stores/views/statistics.dart';

class AmountEntriesControl extends StatelessWidget {
  const AmountEntriesControl({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    StatisticsStore statisticsStore = GetIt.instance<StatisticsStore>();

    return Observer(
      builder: (_) => SizedBox(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl<AmountStatisticEntries>(
          groupValue: statisticsStore.amountStatisticEntries,
          padding: const EdgeInsets.all(0),
          // selectedColor: Theme.of(context).toggleableActiveColor,
          // borderColor: Theme.of(context).toggleableActiveColor,
          // unselectedColor: Theme.of(context).cardColor,
          children: {}..addEntries(
              AmountStatisticEntries.values.map(
                (amount) => MapEntry(
                  amount,
                  Text(
                    amount.number.toString(),
                    style: const TextStyle(
                      fontFeatures: [
                        FontFeature.tabularFigures(),
                      ],
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
