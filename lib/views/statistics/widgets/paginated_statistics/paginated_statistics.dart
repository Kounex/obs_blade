import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../shared/design/design.dart';
import '../../../../shared/general/base/divider.dart';
import '../../../../stores/views/statistics.dart';
import '../../../../types/interfaces/past_stats_data.dart';
import '../stats_entry/stats_entry.dart';
import 'pagination_control.dart';

class PaginatedStatistics extends StatefulWidget {
  final List<PastStatsData> sortedFilteredPastStatsData;

  const PaginatedStatistics(
      {super.key, required this.sortedFilteredPastStatsData});

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
      builder: (context) {
        int amountPages =
            _getMaxPages(statisticsStore.amountStatisticEntries.number);
        if (_page > amountPages) {
          _page = amountPages;
        }

        final int pageStart =
            (_page - 1) * statisticsStore.amountStatisticEntries.number;
        final List<PastStatsData> visibleEntries =
            this.widget.sortedFilteredPastStatsData.sublist(
                  pageStart,
                  pageStart +
                      min(
                          this.widget.sortedFilteredPastStatsData.length -
                              pageStart,
                          statisticsStore.amountStatisticEntries.number),
                );

        /// Identity signature of what is currently shown - changes whenever
        /// the page, the sorting or the filtering changes (the entries are
        /// the same object instances across rebuilds), so unrelated Observer
        /// rebuilds don't retrigger the crossfade
        final int pageSignature =
            Object.hash(_page, Object.hashAll(visibleEntries));

        return Column(
          children: [
            AnimatedSwitcher(
              duration: AppMotion.medium,
              switchInCurve: AppMotion.standard,
              switchOutCurve: AppMotion.exit,
              /// The outgoing page may share entries (and therefore Hero
              /// tags) with the incoming one - disable its Heroes while it
              /// fades out so a tap-to-detail during the crossfade can
              /// never hit duplicate Hero tags
              layoutBuilder: (currentChild, previousChildren) => Stack(
                alignment: Alignment.topCenter,
                children: [
                  ...previousChildren.map(
                    (child) => HeroMode(enabled: false, child: child),
                  ),
                  ?currentChild,
                ],
              ),
              child: ListView.separated(
                key: ValueKey(pageSignature),
                padding: const EdgeInsets.all(0),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) => StaggeredEntrance(
                  index: index,
                  child: StatsEntry(
                    pastStatsData: visibleEntries[index],
                  ),
                ),
                separatorBuilder: (context, index) => const BaseDivider(),
                itemCount: visibleEntries.length,
              ),
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
