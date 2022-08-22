import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/models/past_record_data.dart';
import 'package:obs_blade/shared/general/column_separated.dart';

import '../../models/past_stream_data.dart';
import '../../shared/general/base/card.dart';
import '../../shared/general/hive_builder.dart';
import '../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import '../../stores/views/statistics.dart';
import '../../types/enums/hive_keys.dart';
import '../../types/enums/order.dart';
import '../../types/interfaces/past_stats_data.dart';
import 'widgets/card_header/card_header.dart';
import 'widgets/card_header/sort_filter_panel/sort_filter_panel.dart';
import 'widgets/paginated_statistics/paginated_statistics.dart';
import 'widgets/stats_entry/stats_entry.dart';
import 'widgets/stats_entry_placeholder.dart';

class StatisticsView extends StatefulWidget {
  const StatisticsView({Key? key}) : super(key: key);

  @override
  _StatisticsViewState createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<StatisticsView> {
  // late List<PastStreamData> _pastStreamData;

  // final List<String> _mockedStreamNames = [
  //   'Dark Souls Speeeeeeedrun',
  //   'No Hit attempt (DS 3)',
  //   'Soulsborne Playthrough (this time for real)',
  //   'ELDEN RING HYPE!',
  //   'Age of Empires 4 is out, wtf!!!',
  //   'Endwalker prepssss (FF14)',
  //   'Grind to GC, oof (RL)',
  //   'Hybrid Meteorb Sorc (D2R)',
  //   'Trying out Barb (D2R)',
  //   'Okay okay, wind dudu it is (D2R)',
  //   'INSCRYYYYPTION',
  // ];
  // final Random _random = Random();

  // StreamStats _randomStreamStats() => StreamStats(
  //     streaming: true,
  //     recording: false,
  //     replayBufferActive: true,
  //     bytesPerSec: _random.nextInt(70000),
  //     kbitsPerSec: 6000 - _random.nextInt(500),
  //     strain: _random.nextDouble() * 100,
  //     totalTime: _random.nextInt(64000),
  //     numTotalFrames: _random.nextInt(70000),
  //     numDroppedFrames: _random.nextInt(100),
  //     fps: 60 - (_random.nextDouble() * 20),
  //     renderTotalFrames: _random.nextInt(70000),
  //     renderMissedFrames: _random.nextInt(100),
  //     outputTotalFrames: _random.nextInt(70000),
  //     outputSkippedFrames: _random.nextInt(70000),
  //     averageFrameTime: _random.nextDouble() * 60,
  //     cpuUsage: _random.nextDouble() * 100,
  //     memoryUsage: _random.nextDouble() * 1000,
  //     freeDiskSpace: _random.nextDouble() * 1000000);

  // @override
  // void initState() {
  //   _pastStreamData = List.generate(20 + _random.nextInt(50), (_) {
  //     PastStreamData pastStreamData = PastStreamData();
  //     List.generate(_random.nextInt(1000), (index) {
  //       pastStreamData.addStreamStats(_randomStreamStats());
  //       pastStreamData.name =
  //           _mockedStreamNames[_random.nextInt(_mockedStreamNames.length)];
  //     });
  //     return pastStreamData;
  //   });
  //   super.initState();
  // }

  /// Uses both sort and filter functions
  List<PastStatsData> _sortAndFilterPastStatsData(
          StatisticsStore statisticsStore,
          Iterable<PastStatsData> pastStatsData) =>
      _filterPastStatsData(
          statisticsStore, _sortPastStatsData(statisticsStore, pastStatsData));

  /// Sorts [PastStatsData] accroding to the selected [FilterType] and
  /// [FilterOrder]
  Iterable<PastStatsData> _sortPastStatsData(StatisticsStore statisticsStore,
          Iterable<PastStatsData> pastStatsData) =>
      pastStatsData.toList()
        ..sort((data1, data2) {
          PastStatsData dataOrder1;
          PastStatsData dataOrder2;
          int sortResult = 0;
          if (statisticsStore.filterOrder == Order.Ascending) {
            dataOrder1 = data1;
            dataOrder2 = data2;
          } else {
            dataOrder1 = data2;
            dataOrder2 = data1;
          }
          switch (statisticsStore.filterType) {
            case FilterType.StatisticTime:
              sortResult = dataOrder1.listEntryDateMS.last -
                  dataOrder2.listEntryDateMS.last;
              break;
            case FilterType.TotalTime:
              sortResult = dataOrder1.totalTime! - dataOrder2.totalTime!;
              break;
            case FilterType.Name:
              sortResult = (dataOrder1.name ?? 'Unnamed stream')
                  .compareTo((dataOrder2.name) ?? '');
              break;
            case FilterType.Kbits:
              sortResult = (dataOrder1.kbitsPerSecList
                          .reduce((value, element) => value += element) ~/
                      dataOrder1.kbitsPerSecList.length) -
                  (dataOrder2.kbitsPerSecList
                          .reduce((value, element) => value += element) ~/
                      dataOrder2.kbitsPerSecList.length);
              break;
            default:
              sortResult = dataOrder1.listEntryDateMS.last -
                  dataOrder2.listEntryDateMS.last;
          }

          return sortResult;
        });

  /// Filters [PastStatsData] according to various stuff the user has
  /// set (like amount entries, favorited or not, date range etc.)
  List<PastStatsData> _filterPastStatsData(
      StatisticsStore statisticsStore, Iterable<PastStatsData> pastStatsData) {
    pastStatsData = pastStatsData

        /// Filter statistics which name contain the String entered by the user
        .where((data) => (data.name ?? 'Unnamed stream')
            .toLowerCase()
            .contains(statisticsStore.filterName))

        /// Fitler statistics which are either starred, not starred or both
        .where((data) {
          if (statisticsStore.showOnlyFavorites != null) {
            return statisticsStore.showOnlyFavorites!
                ? data.starred ?? false
                : true;
          }
          return data.starred == null || !data.starred!;
        })

        /// Filter statistics which are either streams, recordings or both
        .where((data) {
          return statisticsStore.statType == StatType.Stream
              ? data is PastStreamData
              : statisticsStore.statType == StatType.Recording
                  ? data is PastRecordData
                  : true;
        })

        /// Filter statistics which are inside the date range the user might
        /// have set
        .where((data) =>
            data.listEntryDateMS.first >=
                (statisticsStore.fromDate?.millisecondsSinceEpoch ?? 0) &&
            data.listEntryDateMS.last <=
                (statisticsStore.toDate?.millisecondsSinceEpoch ??
                    DateTime.now().millisecondsSinceEpoch))
        .where((data) {
          if (statisticsStore.durationFilter != null &&
              int.tryParse(statisticsStore.durationFilterAmount) != null) {
            switch (statisticsStore.durationFilter!) {
              case DurationFilter.Shorter:
                return data.totalTime! <
                    int.parse(statisticsStore.durationFilterAmount) *
                        statisticsStore.durationFilterTimeUnit.factorToS;
              case DurationFilter.Longer:
                return data.totalTime! >
                    int.parse(statisticsStore.durationFilterAmount) *
                        statisticsStore.durationFilterTimeUnit.factorToS;
              case DurationFilter.Between:
                return true;
            }
          }
          return true;
        })

        /// Filter statistics which are not unnamed or specifically unnamed if
        /// user set this checkbox (or tristate)
        .where((data) {
          if (statisticsStore.excludeUnnamedStats != null) {
            return statisticsStore.excludeUnnamedStats!
                ? data.name != null
                : true;
          }
          return data.name == null;
        });

    return pastStatsData.toList();
  }

  @override
  Widget build(BuildContext context) {
    GetIt.instance.resetLazySingleton<StatisticsStore>();
    StatisticsStore statisticsStore = GetIt.instance<StatisticsStore>();

    return Scaffold(
      body: TransculentCupertinoNavBarWrapper(
        title: 'Statistics',
        scrollController:
            ModalRoute.of(context)!.settings.arguments as ScrollController,
        listViewChildren: [
          HiveBuilder<PastStreamData>(
              hiveKey: HiveKeys.PastStreamData,
              builder: (context, pastStreamDataBox, child) {
                return HiveBuilder<PastRecordData>(
                    hiveKey: HiveKeys.PastRecordData,
                    builder: (context, pastRecordDataBox, child) {
                      // List<PastStreamData> pastStreamData = _pastStreamData
                      List<PastStatsData> pastStatsData = [
                        ...pastStreamDataBox.values.toList(),
                        ...pastRecordDataBox.values.toList(),
                      ]..sort((a, b) =>
                          a.listEntryDateMS.last - b.listEntryDateMS.last);

                      PastStreamData? latestStreamData;
                      PastRecordData? latestRecordData;

                      try {
                        latestStreamData =
                            pastStatsData.whereType<PastStreamData>().last;
                      } catch (_) {}

                      try {
                        latestRecordData =
                            pastStatsData.whereType<PastRecordData>().last;
                      } catch (_) {}

                      List<PastStatsData?> latestRecordStreamStat = [
                        latestRecordData,
                        latestStreamData,
                      ]..sort((a, b) =>
                          (b?.listEntryDateMS.last ?? 0) -
                          (a?.listEntryDateMS.last ?? 0));

                      return Column(
                        children: [
                          BaseCard(
                            bottomPadding: 12.0,
                            titlePadding: const EdgeInsets.all(0),
                            titleWidget: const CardHeader(
                              headerDecorationIcon: CupertinoIcons.time_solid,
                              title: 'Latest\nStats.',
                              description:
                                  'The most freshest statistic of your latest streaming and recording session',
                            ),
                            paddingChild: const EdgeInsets.all(0),
                            child: latestRecordStreamStat.isNotEmpty &&
                                    latestRecordStreamStat.any(
                                        (pastStatsData) =>
                                            pastStatsData != null)
                                ? ColumnSeparated(
                                    paddingSeparator:
                                        const EdgeInsets.symmetric(vertical: 0),
                                    children: latestRecordStreamStat
                                        .where((pastStatsData) =>
                                            pastStatsData != null)
                                        .map(
                                          (pastStatsData) => StatsEntry(
                                            pastStatsData: pastStatsData!,
                                          ),
                                        )
                                        .toList(),
                                  )
                                : const StatsEntryPlaceholder(
                                    text:
                                        'You haven\'t streamed or recorded using this app? Or have you deleted all statistic entries?! Whatever it is, you should start streaming / recording!',
                                  ),
                          ),
                          BaseCard(
                            titlePadding: const EdgeInsets.all(0),
                            titleWidget: const CardHeader(
                              title: 'Previous\nStats.',
                              description:
                                  'All previous streaming / recording sessions',
                              additionalCardWidgets: [
                                SortFilterPanel(),
                              ],
                            ),
                            paddingChild: const EdgeInsets.all(0),
                            child: Observer(
                              builder: (_) {
                                /// Only purpose of this line is to omit the debug message of
                                /// missing observable (which is not correct) since I pass the
                                /// store to internal functions to handle sort and filter where
                                /// those observables are used. It even gets rebuilt propely but
                                /// the message keeps coming up
                                statisticsStore.filterName;

                                List<PastStatsData>
                                    sortedFilteredPastStatsData =
                                    _sortAndFilterPastStatsData(
                                  statisticsStore,
                                  pastStatsData
                                    ..removeWhere(
                                      (pastStatsData) => latestRecordStreamStat
                                          .any((latestStat) =>
                                              latestStat == pastStatsData),
                                    ),
                                );
                                return sortedFilteredPastStatsData.isNotEmpty
                                    ? PaginatedStatistics(
                                        sortedFilteredPastStatsData:
                                            sortedFilteredPastStatsData,
                                      )
                                    : StatsEntryPlaceholder(
                                        text: latestRecordStreamStat
                                                .where((latestStat) =>
                                                    latestStat != null)
                                                .isEmpty
                                            ? 'Can\'t find statistics for your previous streams / recordings. Go ahead - stream or record some good stuff!'
                                            : 'No additional statistics to the ones listed above found or none found which match your filters! Stream / record more or change your filters!',
                                      );
                              },
                            ),
                          ),
                        ],
                      );
                    });
              }),
        ],
      ),
    );
  }
}
