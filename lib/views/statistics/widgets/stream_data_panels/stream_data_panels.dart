import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:obs_blade/views/statistics/widgets/stream_data_panels/stream_chart.dart';

import '../../../../models/past_stream_data.dart';
import '../../../../types/classes/api/stream_stats.dart';
import '../../../../types/extensions/list.dart';
import '../../../../utils/styling_helper.dart';

class StreamDataPanels extends StatefulWidget {
  @override
  _StreamDataPanelsState createState() => _StreamDataPanelsState();
}

class _StreamDataPanelsState extends State<StreamDataPanels> {
  List<PastStreamData> _pastStreamData;
  List<bool> _expandedState;

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

    _expandedState = _pastStreamData.map((_) => false).toList();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionPanelList(
      dividerColor: StylingHelper.LIGHT_DIVIDER_COLOR.withOpacity(0.2),
      children: _pastStreamData
          .mapIndexed(
            (pastStreamData, index) => ExpansionPanel(
              canTapOnHeader: true,
              isExpanded: _expandedState[index],
              headerBuilder: (context, expanded) {
                DateTime streamStart = DateTime.fromMillisecondsSinceEpoch(
                        pastStreamData.streamEndedMS)
                    .subtract(
                        Duration(seconds: pastStreamData.totalStreamTime));
                DateTime streamEnd = DateTime.fromMillisecondsSinceEpoch(
                    pastStreamData.streamEndedMS);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                            '${DateFormat.yMMMMd('en_US').format(streamStart)}'),
                        Text('${DateFormat.Hms('en_US').format(streamStart)}')
                      ],
                    ),
                    Text('-'),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text('${DateFormat.yMMMMd('en_US').format(streamEnd)}'),
                        Text('${DateFormat.Hms('en_US').format(streamEnd)}')
                      ],
                    ),
                  ],
                );
              },
              body: Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Column(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) => SizedBox(
                        width: constraints.maxWidth,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 12.0,
                            bottom: 12,
                            right: 24.0,
                          ),
                          child: StreamChart(
                            data: pastStreamData.fpsList
                                .map((fps) => fps.round())
                                .toList(),
                            dataName: 'FPS',
                            chartColor: Colors.greenAccent,
                            streamEndedMS: pastStreamData.streamEndedMS,
                            totalStreamTime: pastStreamData.totalStreamTime,
                          ),
                        ),
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) => SizedBox(
                        width: constraints.maxWidth,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 12.0,
                            bottom: 12,
                            right: 24.0,
                          ),
                          child: StreamChart(
                            data: pastStreamData.cpuUsageList
                                .map((cpu) => cpu.round())
                                .toList(),
                            dataName: 'CPU Usage',
                            dataUnit: '%',
                            chartColor: Colors.blueAccent,
                            streamEndedMS: pastStreamData.streamEndedMS,
                            totalStreamTime: pastStreamData.totalStreamTime,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
      expansionCallback: (panelIndex, isExpanded) =>
          setState(() => _expandedState[panelIndex] = !isExpanded),
    );
  }
}
