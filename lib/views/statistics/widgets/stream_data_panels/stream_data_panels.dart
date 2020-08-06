import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
      totalStreamTime: _random.nextInt(14400),
      numTotalFrames: _random.nextInt(70000),
      numDroppedFrames: _random.nextInt(100),
      fps: _random.nextDouble() * 60,
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
    _pastStreamData = List.generate(_random.nextInt(10), (_) {
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
                    pastStreamData.streamEndedMS);
                DateTime streamEnd = streamStart.add(
                    Duration(milliseconds: pastStreamData.totalStreamTime));
                return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text('${DateFormat.yMMMMd('en_US').format(streamStart)}'),
                    Text(
                        '${DateFormat.Hms('en_US').format(streamStart)} - ${DateFormat.Hms('en_US').format(streamEnd)}')
                  ],
                );
              },
              body: Text('Test'),
            ),
          )
          .toList(),
      expansionCallback: (panelIndex, isExpanded) =>
          setState(() => _expandedState[panelIndex] = !isExpanded),
    );
  }
}
