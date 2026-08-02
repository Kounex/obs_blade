import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/general/tag_box.dart';
import 'package:obs_blade/stores/views/statistics.dart';
import 'package:obs_blade/utils/styling_helper.dart';

class FilterStatus extends StatelessWidget {
  const FilterStatus({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    StatisticsStore statisticsStore = GetIt.instance<StatisticsStore>();

    return Observer(
      builder: (context) {
        final Color pillColor = statisticsStore.isFilterSortActive
            ? Theme.of(context).colorScheme.secondary
            : StylingHelper.lightenDarkenColor(Theme.of(context).cardColor, 8);

        return TagBox(
          color: pillColor,
          label: statisticsStore.isFilterSortActive ? 'ON' : 'OFF',
          labelStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: StylingHelper.surroundingAwareAccent(
                    surroundingColor: pillColor),
              ),
          width: 32.0,
        );
      },
    );
  }
}
