import 'package:flutter/cupertino.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../stores/views/statistics.dart';

class StatTypeControl extends StatelessWidget {
  const StatTypeControl({Key? key});

  @override
  Widget build(BuildContext context) {
    StatisticsStore statisticsStore = GetIt.instance<StatisticsStore>();

    return Observer(
      builder: (context) => SizedBox(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl<StatType>(
          groupValue: statisticsStore.statType,
          padding: const EdgeInsets.all(0),
          children: Map.fromEntries(
            StatType.values.map(
              (statType) => MapEntry(
                statType,
                Text(statType.name),
              ),
            ),
          ),
          onValueChanged: (statType) => statisticsStore.setStatType(statType!),
        ),
      ),
    );
  }
}
