import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../models/past_stream_data.dart';
import '../../../../stores/views/statistics.dart';
import '../../../settings/widgets/action_block.dart/light_divider.dart';
import '../stream_entry/stream_entry.dart';
import 'pagination_control.dart';

class PaginatedStatistics extends StatefulWidget {
  final List<PastStreamData> filteredAndSortedStreamData;

  const PaginatedStatistics(
      {Key? key, required this.filteredAndSortedStreamData})
      : super(key: key);

  @override
  _PaginatedStatisticsState createState() => _PaginatedStatisticsState();
}

class _PaginatedStatisticsState extends State<PaginatedStatistics> {
  int _page = 1;

  int _getMaxPages(int amountStatisticsEntries) =>
      (this.widget.filteredAndSortedStreamData.length / amountStatisticsEntries)
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
              itemBuilder: (context, index) => StreamEntry(
                  pastStreamData: this.widget.filteredAndSortedStreamData[
                      ((_page - 1) *
                              statisticsStore.amountStatisticEntries.number) +
                          index]),
              separatorBuilder: (context, index) => const LightDivider(),
              itemCount: min(
                  this.widget.filteredAndSortedStreamData.length -
                      ((_page - 1) *
                          statisticsStore.amountStatisticEntries.number),
                  statisticsStore.amountStatisticEntries.number),
            ),
            const LightDivider(),
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
