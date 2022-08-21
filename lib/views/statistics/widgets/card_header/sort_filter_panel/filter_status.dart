import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/tag_box.dart';
import 'package:obs_blade/stores/views/statistics.dart';

class FilterStatus extends StatelessWidget {
  const FilterStatus({super.key});

  @override
  Widget build(BuildContext context) {
    StatisticsStore statisticsStore = GetIt.instance<StatisticsStore>();

    return Observer(
      builder: (_) => TagBox(
        color: statisticsStore.isFilterSortActive
            ? Theme.of(context).colorScheme.secondary
            : Theme.of(context).scaffoldBackgroundColor,
        label: statisticsStore.isFilterSortActive ? 'ON' : 'OFF',
        width: 32.0,
      ),
    );
  }
}
