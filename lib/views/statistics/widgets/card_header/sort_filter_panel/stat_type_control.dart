import 'package:flutter/cupertino.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../stores/views/statistics.dart';

class StatTypeControl extends StatelessWidget {
  const StatTypeControl({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    StatisticsStore statisticsStore = GetIt.instance<StatisticsStore>();

    return Observer(
      builder: (_) => SizedBox(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl(
          groupValue: statisticsStore.statType ?? 'null',
          padding: const EdgeInsets.all(0),
          children: {
            'null': const Text('All Stats'),
            StatType.Stream: Text(StatType.Stream.name),
            StatType.Recording: Text(StatType.Recording.name),
          },
          onValueChanged: (value) => statisticsStore
              .setStatType(value == 'null' ? null : value as StatType),
        ),
      ),
    );
  }
}
