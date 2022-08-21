import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/general/base/button.dart';
import 'package:obs_blade/stores/views/statistics.dart';
import 'package:obs_blade/views/statistics/widgets/card_header/sort_filter_panel/filter_duration.dart';
import 'package:obs_blade/views/statistics/widgets/card_header/sort_filter_panel/filter_status.dart';
import 'package:obs_blade/views/statistics/widgets/card_header/sort_filter_panel/stat_type_control.dart';

import '../../../../../shared/general/base/divider.dart';
import '../../../../../shared/general/custom_expansion_tile.dart';
import 'amount_entries_control.dart';
import 'exclude_unnamed_checkbox.dart';
import 'favorite_control.dart';
import 'filter_name.dart';
import 'order_row.dart';
import 'statistics_date_range.dart';

const double _kControlsPadding = 14.0;

class SortFilterPanel extends StatelessWidget {
  const SortFilterPanel({Key? key}) : super(key: key);

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
          headerPadding: const EdgeInsets.all(14.0),
          headerTextStyle: Theme.of(context).textTheme.bodyText2,
          expandedBody: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                const BaseDivider(),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 14.0,
                    right: 14.0,
                    bottom: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: _kControlsPadding + 8.0),
                      const OrderRow(),
                      const SizedBox(height: _kControlsPadding),
                      const FilterName(),
                      const SizedBox(height: _kControlsPadding),
                      const FilterDuration(),
                      const SizedBox(height: _kControlsPadding),
                      const StatisticsDateRange(),
                      const SizedBox(height: _kControlsPadding + 2.0),
                      const FavoriteControl(),
                      const SizedBox(height: _kControlsPadding + 2.0),
                      const StatTypeControl(),
                      const SizedBox(height: _kControlsPadding + 2.0),
                      const AmountEntriesControl(),
                      const SizedBox(height: 4.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const ExcludeUnnamedCheckbox(),
                          BaseButton(
                            text: 'Default',
                            onPressed: () =>
                                GetIt.instance<StatisticsStore>().setDefaults(),
                          ),
                        ],
                      ),
                    ],
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
