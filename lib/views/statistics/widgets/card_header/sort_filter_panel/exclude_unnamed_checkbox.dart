import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../shared/general/base/checkbox.dart';
import '../../../../../stores/views/statistics.dart';

class ExcludeUnnamedCheckbox extends StatelessWidget {
  const ExcludeUnnamedCheckbox({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    StatisticsStore statisticsStore = GetIt.instance<StatisticsStore>();

    return Transform.translate(
      offset: const Offset(-12.0, 0.0),
      child: Row(
        children: [
          Observer(
            builder: (_) => BaseCheckbox(
              value: statisticsStore.excludeUnnamedStats,
              tristate: true,
              onChanged: (excludeUnnamedStats) {
                HapticFeedback.lightImpact();

                statisticsStore.setExcludeUnnamedStats(excludeUnnamedStats);
              },
            ),
          ),
          Text(
            'Exclude unnamed entries',
            style: Theme.of(context).textTheme.subtitle2,
          ),
        ],
      ),
    );
  }
}
