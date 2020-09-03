import 'dart:math';
import 'package:flutter/material.dart';
import 'package:obs_blade/models/past_stream_data.dart';
import 'package:obs_blade/shared/general/base_card.dart';
import 'package:obs_blade/types/classes/api/stream_stats.dart';
import 'package:obs_blade/views/statistics/widgets/stream_entry.dart/stream_entry.dart';

import '../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import 'widgets/stream_data_panels/stream_data_panels.dart';

class StatisticsView extends StatefulWidget {
  @override
  _StatisticsViewState createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<StatisticsView> {
  List<PastStreamData> _pastStreamData;
  Random _random = Random();

  StreamStats _randomStreamStats() => StreamStats(
      streaming: true,
      recording: false,
      replayBufferActive: true,
      bytesPerSec: _random.nextInt(70000),
      kbitsPerSec: _random.nextInt(6000),
      strain: _random.nextDouble() * 100,
      totalStreamTime: _random.nextInt(64000),
      numTotalFrames: _random.nextInt(70000),
      numDroppedFrames: _random.nextInt(100),
      fps: 60 - (_random.nextDouble() * 20),
      renderTotalFrames: _random.nextInt(70000),
      renderMissedFrames: _random.nextInt(100),
      outputTotalFrames: _random.nextInt(70000),
      outputSkippedFrames: _random.nextInt(70000),
      averageFrameTime: _random.nextDouble() * 60,
      cpuUsage: _random.nextDouble() * 100,
      memoryUsage: _random.nextDouble() * 1000000,
      freeDiskSpace: _random.nextDouble() * 1000000);

  @override
  void initState() {
    _pastStreamData = List.generate(20 + _random.nextInt(50), (_) {
      PastStreamData pastStreamData = PastStreamData();
      List.generate(_random.nextInt(1000), (index) {
        pastStreamData.addStreamStats(_randomStreamStats());
      });
      pastStreamData.finishUpStats();
      return pastStreamData;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TransculentCupertinoNavBarWrapper(
        appBarTitle: 'Statistics',
        scrollController: ModalRoute.of(context).settings.arguments,
        listViewChildren: [
          BaseCard(
            title: 'Latest Stream',
            noPaddingChild: true,
            child: StreamEntry(pastStreamData: _pastStreamData.first),
          ),
          BaseCard(
            title: 'Other Streams',
            noPaddingChild: true,
            child: Column(
              children: [
                ..._pastStreamData.map(
                  (pastStreamData) => Column(
                    children: [
                      StreamEntry(pastStreamData: pastStreamData),
                      Divider(
                        height: 0.0,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
