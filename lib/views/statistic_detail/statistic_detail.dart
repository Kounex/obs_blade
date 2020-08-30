import 'package:flutter/material.dart';
import 'package:obs_blade/models/past_stream_data.dart';
import 'package:obs_blade/shared/general/formatted_text.dart';
import 'package:obs_blade/shared/general/transculent_cupertino_navbar_wrapper.dart';
import 'package:obs_blade/views/dashboard/widgets/stream_widgets/stats/stats_container.dart';
import 'package:obs_blade/views/statistics/widgets/stream_data_panels/stream_chart.dart';

class StatisticDetailView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    PastStreamData pastStreamData = ModalRoute.of(context).settings.arguments;

    return Scaffold(
      body: TransculentCupertinoNavBarWrapper(
        appBarTitle: pastStreamData.name ?? 'Unnamed stream',
        listViewChildren: [
          StreamChart(
            data: pastStreamData.fpsList.map((fps) => fps.round()).toList(),
            dataName: 'FPS',
            chartColor: Colors.greenAccent,
            streamEndedMS: pastStreamData.streamEndedMS,
            totalStreamTime: pastStreamData.totalStreamTime,
          ),
          Divider(),
          StreamChart(
            data:
                pastStreamData.cpuUsageList.map((cpu) => cpu.round()).toList(),
            dataName: 'CPU Usage',
            dataUnit: '%',
            chartColor: Colors.blueAccent,
            streamEndedMS: pastStreamData.streamEndedMS,
            totalStreamTime: pastStreamData.totalStreamTime,
          ),
          Divider(),
          StreamChart(
            data: pastStreamData.kbitsPerSecList,
            dataName: 'kbit/s',
            yPuffer: 500,
            yInterval: 500,
            chartColor: Colors.orangeAccent,
            streamEndedMS: pastStreamData.streamEndedMS,
            totalStreamTime: pastStreamData.totalStreamTime,
          ),
          Divider(),
          StreamChart(
            data: pastStreamData.memoryUsageList
                .map((ram) => (ram / 1000).round())
                .toList(),
            dataName: 'RAM',
            dataUnit: 'MB',
            yPuffer: 200,
            yInterval: 200,
            chartColor: Colors.redAccent,
            streamEndedMS: pastStreamData.streamEndedMS,
            totalStreamTime: pastStreamData.totalStreamTime,
          ),
          Divider(),
          StatsContainer(
            title: 'Stuff',
            children: [
              FormattedText(
                label: 'Total Output Frames (encoder)',
                text: pastStreamData.outputTotalFrames.toString(),
                width: 200.0,
              ),
              FormattedText(
                label: 'Total Output Frames (render)',
                text: pastStreamData.renderTotalFrames.toString(),
                width: 200.0,
              ),
              FormattedText(
                label: 'Missed Frames (render)',
                text: pastStreamData.renderMissedFrames.toString(),
                width: 200.0,
              ),
              FormattedText(
                label: 'Skipped Frames (encoder)',
                text: pastStreamData.outputSkippedFrames.toString(),
                width: 200.0,
              ),
              FormattedText(
                label: 'Dropped Frames (%)',
                text: pastStreamData.strain?.toString(),
                width: 200.0,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
