import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/general/date_range/date_range.dart';
import '../../../../../stores/views/statistics.dart';

class StatisticsDateRange extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    StatisticsStore statisticsStore = context.read<StatisticsStore>();

    return Observer(
      builder: (_) => DateRange(
        selectedFromDate: statisticsStore.fromDate,
        updateFromDate: (date) => statisticsStore.setFromDate(date),
        selectedToDate: statisticsStore.toDate,
        updateToDate: (date) => statisticsStore.setToDate(
            date?.add(Duration(days: 1)).subtract(Duration(milliseconds: 1))),
      ),
    );
  }
}
