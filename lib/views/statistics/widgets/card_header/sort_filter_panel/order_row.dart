import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../shared/animator/order_button.dart';
import '../../../../../shared/general/cupertino_dropdown.dart';
import '../../../../../stores/views/statistics.dart';

const List<FilterType> kActiveFilterTypes = [
  FilterType.Name,
  FilterType.StatisticTime,
  FilterType.TotalTime,
];

class OrderRow extends StatelessWidget {
  const OrderRow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    StatisticsStore statisticsStore = GetIt.instance<StatisticsStore>();

    return Row(
      children: [
        Expanded(
          child: Observer(
            builder: (_) => CupertinoDropdown<FilterType>(
              value: statisticsStore.filterType,
              items: FilterType.values
                  .where(
                      (filterType) => kActiveFilterTypes.contains(filterType))
                  .map((filterType) => DropdownMenuItem<FilterType>(
                        value: filterType,
                        child: Text(filterType.text),
                      ))
                  .toList(),
              selectedItemBuilder: (context) => FilterType.values
                  .map((filterType) => Text(filterType.text))
                  .toList(),
              onChanged: (filterType) =>
                  statisticsStore.setFilterType(filterType!),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 14.0),
          child: OrderButton(
            toggle: statisticsStore.toggleFilterOrder,
          ),
        ),
      ],
    );
  }
}
