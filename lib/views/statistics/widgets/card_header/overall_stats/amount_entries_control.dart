import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:obs_blade/stores/views/statistics.dart';
import 'package:provider/provider.dart';

class AmountEntriesControl extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    StatisticsStore statisticsStore = context.watch<StatisticsStore>();

    return Observer(
      builder: (_) => SizedBox(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl(
          groupValue: statisticsStore.amountStatisticEntries,
          padding: EdgeInsets.all(0),
          // selectedColor: Theme.of(context).toggleableActiveColor,
          // borderColor: Theme.of(context).toggleableActiveColor,
          // unselectedColor: Theme.of(context).cardColor,
          children: {}..addEntries(
              AmountStatisticEntries.values.map(
                (amount) => MapEntry(
                  amount,
                  Text(amount.numberText),
                ),
              ),
            ),
          onValueChanged: (amountEntries) =>
              statisticsStore.setAmountStatisticEntries(amountEntries),
        ),
      ),
    );
  }
}
