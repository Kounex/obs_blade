import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/design/design.dart';
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
        final bool active = statisticsStore.isFilterSortActive;

        /// Calm-chip treatment (mock Statistics notes): active = highlight
        /// tint + highlightText (control state, token-delta rule 3),
        /// inactive = neutral pill + dim label
        final Color highlight = Theme.of(context).colorScheme.secondary;
        final Color pillColor = active
            ? highlight.withValues(alpha: 0.16)
            : StylingHelper.lightenDarkenColor(Theme.of(context).cardColor, 8);

        return TagBox(
          color: pillColor,
          label: active ? 'ON' : 'OFF',
          labelStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: active
                    ? Theme.of(context)
                        .extension<AppTextColors>()!
                        .highlightText
                    : Theme.of(context)
                        .extension<AppTextColors>()!
                        .textSecondary,
              ),
          width: 32.0,
        );
      },
    );
  }
}
