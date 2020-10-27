import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../../../../../stores/views/statistics.dart';
import 'text_field_date.dart';

class DateRange extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    StatisticsStore statisticsStore = context.watch<StatisticsStore>();

    return Observer(
      builder: (_) => Row(
        children: [
          Expanded(
            child: TextFieldDate(
              placeholder: 'From...',
              selectedDate: statisticsStore.fromDate,
              maximumDate: statisticsStore.toDate,
              updateDateTime: (date) => statisticsStore.setFromDate(date),
            ),
          ),
          SizedBox(width: 12.0),
          Expanded(
            child: TextFieldDate(
              placeholder: 'To...',
              selectedDate: statisticsStore.toDate,
              minimumDate: statisticsStore.fromDate,
              updateDateTime: (date) => statisticsStore.setToDate(date
                  ?.add(Duration(days: 1))
                  ?.subtract(Duration(milliseconds: 1))),
            ),
          ),
        ],
      ),
    );
  }
}
