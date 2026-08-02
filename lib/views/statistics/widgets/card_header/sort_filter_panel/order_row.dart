import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../shared/animator/order_button.dart';
import '../../../../../shared/design/design.dart';
import '../../../../../shared/general/cupertino_dropdown.dart';
import '../../../../../stores/views/statistics.dart';

const List<FilterType> kActiveFilterTypes = [
  FilterType.Name,
  FilterType.StatisticTime,
  FilterType.TotalTime,
];

/// Shared slot height so the dropdown and the [OrderButton] read as one
/// control row (the dropdown keeps its intrinsic field height, centered)
const double _kControlHeight = 40.0;

class OrderRow extends StatelessWidget {
  const OrderRow({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    StatisticsStore statisticsStore = GetIt.instance<StatisticsStore>();

    return Observer(builder: (context) {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: _kControlHeight,
              child: Center(
                child: CupertinoDropdown<FilterType>(
                  value: statisticsStore.filterType,
                  items: kActiveFilterTypes
                      .map((filterType) => DropdownMenuItem<FilterType>(
                            value: filterType,
                            child: Text(filterType.text),
                          ))
                      .toList(),
                  selectedItemBuilder: (context) => kActiveFilterTypes
                      .map((filterType) => Text(filterType.text))
                      .toList(),
                  onChanged: (filterType) =>
                      statisticsStore.setFilterType(filterType!),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.lg),
            child: SizedBox(
              height: _kControlHeight,
              width: _kControlHeight,
              child: OrderButton(
                order: statisticsStore.filterOrder,
                toggle: statisticsStore.toggleFilterOrder,
              ),
            ),
          ),
        ],
      );
    });
  }
}
