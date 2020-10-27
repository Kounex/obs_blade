import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../../../../stores/views/statistics.dart';

const List<FilterType> kActiveFilterTypes = [
  FilterType.Name,
  FilterType.StatisticTime,
  FilterType.TotalTime,
];

class OrderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    StatisticsStore statisticsStore = context.watch<StatisticsStore>();

    return Observer(
      builder: (_) => Row(
        children: [
          Expanded(
            child: Stack(
              children: [
                /// Dirty workaround... but I mean it works and is minimalistic :x
                /// I want the dopdown to look just like the other textfields and instead
                /// of writing "unnecessary" code to immitate the look and feel of them
                /// I just use it for the visual part. By setting it to readonly it will
                /// not have any focus and should not interfere in any way
                CupertinoTextField(readOnly: true),
                Container(
                  padding: EdgeInsets.only(
                      left: 6.0, top: 4.0, bottom: 4.0, right: 2.0),
                  child: DropdownButton<FilterType>(
                    underline: Container(),
                    isExpanded: true,
                    isDense: true,
                    value: statisticsStore.filterType,
                    dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                    items: FilterType.values
                        .where((filterType) =>
                            kActiveFilterTypes.contains(filterType))
                        .map(
                          (filterType) => DropdownMenuItem<FilterType>(
                            value: filterType,
                            child: Text(filterType.text),
                          ),
                        )
                        .toList(),
                    selectedItemBuilder: (context) => FilterType.values
                        .map(
                          (filterType) => Text(filterType.text),
                        )
                        .toList(),
                    onChanged: (filterType) =>
                        statisticsStore.setFilterType(filterType),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 14.0),
            child: GestureDetector(
              onTap: () => statisticsStore.toggleFilterOrder(),
              child: Container(
                padding: EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).toggleableActiveColor,
                ),
                child: Icon(
                  statisticsStore.filterOrder == FilterOrder.Ascending
                      ? CupertinoIcons.up_arrow
                      : CupertinoIcons.down_arrow,
                  size: 22.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
