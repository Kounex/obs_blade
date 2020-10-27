import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:obs_blade/stores/views/statistics.dart';
import 'package:obs_blade/views/statistics/widgets/paginated_statistics.dart';
import 'package:provider/provider.dart';

import '../../models/past_stream_data.dart';
import '../../shared/general/base_card.dart';
import '../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import '../../types/enums/hive_keys.dart';
import 'widgets/card_header/card_header.dart';
import 'widgets/stream_entry.dart';
import 'widgets/stream_entry_placeholder.dart';

class StatisticsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (context) => StatisticsStore(),
      child: _StatisticsView(),
    );
  }
}

class _StatisticsView extends StatefulWidget {
  @override
  _StatisticsViewState createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<_StatisticsView> {
  // List<ReactionDisposer> _disposers = [];

  // List<PastStreamData> _pastStreamData;
  // Random _random = Random();

  // StreamStats _randomStreamStats() => StreamStats(
  //     streaming: true,
  //     recording: false,
  //     replayBufferActive: true,
  //     bytesPerSec: _random.nextInt(70000),
  //     kbitsPerSec: _random.nextInt(6000),
  //     strain: _random.nextDouble() * 100,
  //     totalStreamTime: _random.nextInt(64000),
  //     numTotalFrames: _random.nextInt(70000),
  //     numDroppedFrames: _random.nextInt(100),
  //     fps: 60 - (_random.nextDouble() * 20),
  //     renderTotalFrames: _random.nextInt(70000),
  //     renderMissedFrames: _random.nextInt(100),
  //     outputTotalFrames: _random.nextInt(70000),
  //     outputSkippedFrames: _random.nextInt(70000),
  //     averageFrameTime: _random.nextDouble() * 60,
  //     cpuUsage: _random.nextDouble() * 100,
  //     memoryUsage: _random.nextDouble() * 1000000,
  //     freeDiskSpace: _random.nextDouble() * 1000000);

  // @override
  // void initState() {
  //   _pastStreamData = List.generate(20 + _random.nextInt(50), (_) {
  //     PastStreamData pastStreamData = PastStreamData();
  //     List.generate(_random.nextInt(1000), (index) {
  //       pastStreamData.addStreamStats(_randomStreamStats());
  //     });
  //     pastStreamData.finishUpStats();
  //     return pastStreamData;
  //   });

  // _disposers.add(
  //     reaction((_) => context.read<TabsStore>().performTabClickAction,
  //         (performTabClickAction) {
  //   if (performTabClickAction && ModalRoute.of(context).isCurrent) {
  //     context.read<TabsStore>().setPerformTabClickAction(false);
  //   }
  // }));
  // super.initState();
  // }

  /// Uses both sort and filter functions
  List<PastStreamData> _sortAndFilterPastStreamData(
          StatisticsStore statisticsStore,
          Iterable<PastStreamData> pastStreamData) =>
      _filterStreamData(
          statisticsStore, _sortStreamData(statisticsStore, pastStreamData));

  /// Sorts [PastStreamData] accroding to the selected [FilterType] and
  /// [FilterOrder]
  Iterable<PastStreamData> _sortStreamData(StatisticsStore statisticsStore,
          Iterable<PastStreamData> pastStreamData) =>
      pastStreamData.toList()
        ..sort((data1, data2) {
          PastStreamData dataOrder1;
          PastStreamData dataOrder2;
          int sortResult = 0;
          if (statisticsStore.filterOrder == FilterOrder.Ascending) {
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
              sortResult =
                  dataOrder1.totalStreamTime - dataOrder2.totalStreamTime;
              break;
            case FilterType.Name:
              sortResult = dataOrder1.name.compareTo(dataOrder2.name);
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

  /// Filters [PastStreamData] according to various stuff the user has
  /// set (like amount entries, favorited or not, date range etc.)
  List<PastStreamData> _filterStreamData(StatisticsStore statisticsStore,
      Iterable<PastStreamData> pastStreamData) {
    pastStreamData = pastStreamData
        .where((data) => (data.name ?? '')
            .toLowerCase()
            .contains(statisticsStore.filterName))
        .where((data) {
      if (statisticsStore.showOnlyFavorites != null) {
        return statisticsStore.showOnlyFavorites ? data.starred ?? false : true;
      }
      return data.starred == null || !data.starred;
    });

    if (int.tryParse(statisticsStore.amountStatisticEntries.numberText) !=
        null) {
      pastStreamData = pastStreamData
          .take(int.parse(statisticsStore.amountStatisticEntries.numberText));
    }

    return pastStreamData.toList();
  }

  @override
  Widget build(BuildContext context) {
    StatisticsStore statisticsStore = context.watch<StatisticsStore>();

    return Scaffold(
      body: TransculentCupertinoNavBarWrapper(
        title: 'Statistics',
        scrollController: ModalRoute.of(context).settings.arguments,
        listViewChildren: [
          ValueListenableBuilder(
            valueListenable:
                Hive.box<PastStreamData>(HiveKeys.PastStreamData.name)
                    .listenable(),
            builder: (context, Box<PastStreamData> pastStreamDataBox, child) {
              List<PastStreamData> pastStreamData = pastStreamDataBox.values
                  .toList()
                    ..sort((a, b) =>
                        a.listEntryDateMS.last - b.listEntryDateMS.last);
              return Column(
                children: [
                  BaseCard(
                    bottomPadding: 12.0,
                    titlePadding: EdgeInsets.all(0),
                    titleWidget: CardHeader(
                      headerDecorationIcon: CupertinoIcons.time_solid,
                      title: 'Latest\nStream.',
                      description:
                          'The most freshest statistic of your latest stream session',
                    ),
                    paddingChild: EdgeInsets.all(0),
                    child: pastStreamData.isNotEmpty
                        ? StreamEntry(
                            pastStreamData: pastStreamData.reversed.first)
                        : StreamEntryPlaceholder(
                            text:
                                'You haven\'t streamed using this app or deleted all statistic entries?! Whatever it is, you should start streaming!',
                          ),
                  ),
                  Observer(
                    builder: (_) {
                      List<PastStreamData> sortedFilteredStreamData =
                          _sortAndFilterPastStreamData(
                        statisticsStore,
                        pastStreamData.reversed.skip(1),
                      );
                      return BaseCard(
                        titlePadding: EdgeInsets.all(0),
                        titleWidget: CardHeader(
                          statsType: StatsType.AllPrevious,
                          title: 'Previous\nStreams.',
                          description:
                              'All the statistics of your smexy stream sessions',
                        ),
                        paddingChild: EdgeInsets.all(0),
                        child: sortedFilteredStreamData.length > 0
                            ? PaginatedStatistics(
                                filteredAndSortedStreamData:
                                    sortedFilteredStreamData,
                              )
                            : StreamEntryPlaceholder(
                                text:
                                    'Can\'t find statistics for your previous streams. Go ahead - stream some good stuff!',
                              ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
