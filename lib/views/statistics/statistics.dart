import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:obs_blade/shared/general/app_bar_cupertino_actions.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/views/statistics/widgets/stream_entry_placeholder/stream_entry_placeholder.dart';

import '../../models/past_stream_data.dart';
import '../../shared/general/base_card.dart';
import '../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import '../../types/classes/api/stream_stats.dart';
import 'widgets/card_header/card_header.dart';
import 'widgets/stream_entry.dart/stream_entry.dart';

class StatisticsView extends StatefulWidget {
  @override
  _StatisticsViewState createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<StatisticsView> {
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
  //   super.initState();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TransculentCupertinoNavBarWrapper(
        appBarTitle: 'Statistics',
        scrollController: ModalRoute.of(context).settings.arguments,
        listViewChildren: [
          ValueListenableBuilder(
            valueListenable:
                Hive.box<PastStreamData>(HiveKeys.PastStreamData.name)
                    .listenable(),
            builder: (context, Box<PastStreamData> pastStreamDataBox, child) =>
                Column(
              children: [
                BaseCard(
                  titlePadding:
                      EdgeInsets.only(left: 14.0, right: 14.0, bottom: 12.0),
                  titleWidget: CardHeader(
                    title: 'Latest\nStream.',
                    description: 'Your latest stream',
                  ),
                  noPaddingChild: true,
                  child: pastStreamDataBox.isNotEmpty
                      ? StreamEntry(
                          pastStreamData: pastStreamDataBox.values.first)
                      : StreamEntryPlaceholder(
                          text:
                              'You haven\'t streamed using this app!\nOr deleted all statistic entries?!'),
                ),
                BaseCard(
                  titlePadding:
                      EdgeInsets.only(left: 14.0, right: 14.0, bottom: 12.0),
                  titleWidget: CardHeader(
                    title: 'Previous\nStreams.',
                  ),
                  noPaddingChild: true,
                  child: pastStreamDataBox.values.length > 1
                      ? Column(
                          children: [
                            ...pastStreamDataBox.values.skip(1).map(
                                  (pastStreamData) => Column(
                                    children: [
                                      StreamEntry(
                                          pastStreamData: pastStreamData),
                                      Divider(
                                        height: 0.0,
                                      ),
                                    ],
                                  ),
                                ),
                          ],
                        )
                      : StreamEntryPlaceholder(
                          text:
                              'Can\'t find statistics for your previous streams\nGo ahead, stream some good stuff!'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
