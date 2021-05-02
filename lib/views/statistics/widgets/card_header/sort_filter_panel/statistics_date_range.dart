import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/date_range/date_range.dart';
import 'package:obs_blade/stores/views/statistics.dart';
import 'package:provider/provider.dart';

class StatisticsDateRange extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    StatisticsStore statisticsStore = context.read<StatisticsStore>();

    return DateRange(
      selectedFromDate: statisticsStore.fromDate,
      updateFromDate: (date) => statisticsStore.setFromDate(date),
      selectedToDate: statisticsStore.toDate,
      updateToDate: (date) => statisticsStore.setToDate(
          date?.add(Duration(days: 1)).subtract(Duration(milliseconds: 1))),
    );
  }
}
