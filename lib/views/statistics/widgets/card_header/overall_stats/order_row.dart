import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../../../../stores/views/statistics.dart';

class OrderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    StatisticsStore statisticsStore = context.watch<StatisticsStore>();

    return Observer(
      builder: (_) => Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.only(top: 4.0, bottom: 4.0, right: 8.0),
              // decoration: BoxDecoration(
              //   border: Border.all(
              //     color: CupertinoDynamicColor.resolve(
              //         CupertinoDynamicColor.withBrightness(
              //           color: CupertinoColors.white,
              //           darkColor: CupertinoColors.black,
              //         ),
              //         context),
              //   ),
              //   borderRadius: BorderRadius.circular(4.0),
              // ),
              child: DropdownButton<FilterType>(
                // underline: Container(),
                isExpanded: true,
                isDense: true,
                value: statisticsStore.filterType,
                dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                items: FilterType.values
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
