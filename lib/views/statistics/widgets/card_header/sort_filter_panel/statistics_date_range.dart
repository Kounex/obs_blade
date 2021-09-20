import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../shared/general/date_range/date_range.dart';
import '../../../../../stores/views/statistics.dart';

class StatisticsDateRange extends StatelessWidget {
  const StatisticsDateRange({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    StatisticsStore statisticsStore = GetIt.instance<StatisticsStore>();

    return Observer(
      builder: (_) => DateRange(
        selectedFromDate: statisticsStore.fromDate,
        updateFromDate: (date) => statisticsStore.setFromDate(date),
        selectedToDate: statisticsStore.toDate,
        updateToDate: (date) => statisticsStore.setToDate(date
            ?.add(const Duration(days: 1))
            .subtract(const Duration(milliseconds: 1))),
      ),
    );
  }
}
