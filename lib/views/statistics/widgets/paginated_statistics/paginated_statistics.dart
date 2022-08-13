import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../shared/general/base/divider.dart';
import '../../../../stores/views/statistics.dart';
import '../../../../types/interfaces/past_stats_data.dart';
import '../stats_entry/stats_entry.dart';
import 'pagination_control.dart';

class PaginatedStatistics extends StatefulWidget {
  final List<PastStatsData> sortedFilteredPastStatsData;

  const PaginatedStatistics(
      {Key? key, required this.sortedFilteredPastStatsData})
      : super(key: key);

  @override
  _PaginatedStatisticsState createState() => _PaginatedStatisticsState();
}

class _PaginatedStatisticsState extends State<PaginatedStatistics> {
  int _page = 1;

  int _getMaxPages(int amountStatisticsEntries) =>
      (this.widget.sortedFilteredPastStatsData.length / amountStatisticsEntries)
          .ceil();

  @override
  Widget build(BuildContext context) {
    StatisticsStore statisticsStore = GetIt.instance<StatisticsStore>();

    return Observer(
      builder: (_) {
        int amountPages =
            _getMaxPages(statisticsStore.amountStatisticEntries.number);
        if (_page > amountPages) {
          _page = amountPages;
        }
        return Column(
          children: [
            ListView.separated(
              padding: const EdgeInsets.all(0),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) => StatsEntry(
                  pastStatsData: this.widget.sortedFilteredPastStatsData[
                      ((_page - 1) *
                              statisticsStore.amountStatisticEntries.number) +
                          index]),
              separatorBuilder: (context, index) => const BaseDivider(),
              itemCount: min(
                  this.widget.sortedFilteredPastStatsData.length -
                      ((_page - 1) *
                          statisticsStore.amountStatisticEntries.number),
                  statisticsStore.amountStatisticEntries.number),
            ),
            const BaseDivider(),
            PaginationControl(
              currentPage: _page,
              amountPages: amountPages,
              onBackMax: _page > 1 ? () => setState(() => _page = 1) : null,
              onBack: _page > 1 ? () => setState(() => _page--) : null,
              onForward:
                  _page < amountPages ? () => setState(() => _page++) : null,
              onForwardMax: _page < amountPages
                  ? () => setState(() => _page = amountPages)
                  : null,
            ),
          ],
        );
      },
    );
  }
}
