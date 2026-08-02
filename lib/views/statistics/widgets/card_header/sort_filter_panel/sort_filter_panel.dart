import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/general/base/button.dart';
import 'package:obs_blade/stores/views/statistics.dart';
import 'package:obs_blade/utils/styling_helper.dart';
import 'package:obs_blade/views/statistics/widgets/card_header/sort_filter_panel/filter_duration.dart';
import 'package:obs_blade/views/statistics/widgets/card_header/sort_filter_panel/filter_status.dart';
import 'package:obs_blade/views/statistics/widgets/card_header/sort_filter_panel/stat_type_control.dart';

import '../../../../../shared/design/design.dart';
import '../../../../../shared/general/base/divider.dart';
import '../../../../../shared/general/custom_expansion_tile.dart';
import 'amount_entries_control.dart';
import 'exclude_unnamed_checkbox.dart';
import 'favorite_control.dart';
import 'filter_name.dart';
import 'order_row.dart';
import 'statistics_date_range.dart';

class SortFilterPanel extends StatelessWidget {
  const SortFilterPanel({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const BaseDivider(),
        CustomExpansionTile(
          headerText: 'Sort and filter panel',
          trailing: const Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: FilterStatus(),
          ),
          headerPadding: const EdgeInsets.all(AppSpacing.md),
          headerTextStyle: Theme.of(context).textTheme.bodyMedium,
          expandedBody: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                const BaseDivider(),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Container(
                    width: double.infinity,

                    /// No top padding here - each [_PanelSection] already
                    /// brings its own `AppSpacing.lg` top rhythm
                    padding: const EdgeInsets.only(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      bottom: AppSpacing.lg,
                    ),
                    decoration: BoxDecoration(
                      color: StylingHelper.lightenDarkenColor(
                          Theme.of(context).cardColor, 8),
                      borderRadius:
                          const BorderRadius.all(Radius.circular(AppRadius.md)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _PanelSection(
                          label: 'Sort',
                          child: OrderRow(),
                        ),
                        const _PanelSection(
                          label: 'Filter',
                          child: Column(
                            children: [
                              FilterName(),
                              SizedBox(height: AppSpacing.md),
                              FilterDuration(),
                              SizedBox(height: AppSpacing.md),
                              StatisticsDateRange(),
                            ],
                          ),
                        ),
                        const _PanelSection(
                          label: 'Show',
                          child: Column(
                            children: [
                              FavoriteControl(),
                              SizedBox(height: AppSpacing.md),
                              StatTypeControl(),
                              SizedBox(height: AppSpacing.md),
                              AmountEntriesControl(),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const ExcludeUnnamedCheckbox(),
                            BaseButton(
                              text: 'Default',
                              onPressed: () =>
                                  GetIt.instance<StatisticsStore>()
                                      .setDefaults(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Caption label above a group of related controls (keeps the control
/// order/semantics of the previous flat list, only visually grouped)
class _PanelSection extends StatelessWidget {
  final String label;
  final Widget child;

  const _PanelSection({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              this.label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: Theme.of(context).textTheme.bodySmall!.color,
                  ),
            ),
          ),
          this.child,
        ],
      ),
    );
  }
}
