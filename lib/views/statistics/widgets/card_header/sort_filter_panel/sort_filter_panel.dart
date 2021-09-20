import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/general/custom_expansion_tile.dart';
import '../../../../settings/widgets/action_block.dart/light_divider.dart';
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
        const LightDivider(),
        CustomExpansionTile(
          headerText: 'Expand to sort and filter your statistics!',
          headerPadding: const EdgeInsets.all(14.0),
          headerTextStyle: Theme.of(context).textTheme.bodyText2,
          expandedBody: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                const LightDivider(),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 14.0,
                    right: 14.0,
                    bottom: 12.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SizedBox(height: _kControlsPadding + 8.0),
                      OrderRow(),
                      SizedBox(height: _kControlsPadding),
                      FilterName(),
                      SizedBox(height: _kControlsPadding),
                      StatisticsDateRange(),
                      SizedBox(height: _kControlsPadding + 2.0),
                      FavoriteControl(),
                      SizedBox(height: _kControlsPadding + 2.0),
                      AmountEntriesControl(),
                      SizedBox(height: 4.0),
                      ExcludeUnnamedCheckbox(),
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
