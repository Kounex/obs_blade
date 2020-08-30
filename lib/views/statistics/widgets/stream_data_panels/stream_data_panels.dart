import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:obs_blade/views/statistics/widgets/stream_data_panels/stream_chart.dart';

import '../../../../models/past_stream_data.dart';
import '../../../../types/classes/api/stream_stats.dart';
import '../../../../types/extensions/list.dart';
import '../../../../utils/styling_helper.dart';

class StreamDataPanels extends StatefulWidget {
  final List<PastStreamData> pastStreamData;

  StreamDataPanels({@required this.pastStreamData});

  @override
  _StreamDataPanelsState createState() => _StreamDataPanelsState();
}

class _StreamDataPanelsState extends State<StreamDataPanels> {
  List<bool> _expandedState;

  @override
  void initState() {
    _expandedState = widget.pastStreamData.map((_) => false).toList();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionPanelList(
      dividerColor: StylingHelper.LIGHT_DIVIDER_COLOR.withOpacity(0.2),
      children: widget.pastStreamData
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
