import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../shared/design/design.dart';
import '../../../../../stores/views/statistics.dart';

class StatTypeControl extends StatelessWidget {
  const StatTypeControl({super.key});

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
        child: CupertinoSlidingSegmentedControl<StatType>(
          groupValue: statisticsStore.statType,
          padding: const EdgeInsets.all(0),
          backgroundColor: segBackground,
          thumbColor: segThumb,
          children: Map.fromEntries(
            StatType.values.map(
              (statType) => MapEntry(
                statType,
                Text(
                  statType.name,
                  style: TextStyle(
                    color: statisticsStore.statType == statType
                        ? textColors.textPrimary
                        : textColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          onValueChanged: (statType) => statisticsStore.setStatType(statType!),
        ),
      ),
    );
  }
}
