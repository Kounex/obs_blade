import 'package:flutter/material.dart';
import 'package:obs_blade/shared/dialogs/confirmation.dart';
import 'package:obs_blade/utils/dialog_handler.dart';

import '../../models/past_stream_data.dart';
import '../../shared/general/app_bar_cupertino_actions.dart';
import '../../shared/general/formatted_text.dart';
import '../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import '../dashboard/widgets/stream_widgets/stats/stats_container.dart';
import '../statistics/widgets/stream_chart/stream_chart.dart';

class StatisticDetailView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    PastStreamData pastStreamData = (ModalRoute.of(context).settings.arguments
        as Map<String, dynamic>)['pastStreamData'];
    ScrollController scrollController = (ModalRoute.of(context)
        .settings
        .arguments as Map<String, dynamic>)['scrollController'];
    if (scrollController.hasClients)
      scrollController.detach(scrollController.position);

    return Scaffold(
      body: TransculentCupertinoNavBarWrapper(
        scrollController: scrollController,
        appBarTitle: pastStreamData.name ?? 'Unnamed stream',
        actions: AppBarCupertinoActions(
          actionSheetTitle: 'Actions',
          actions: [
            AppBarCupertinoActionEntry(title: 'Rename'),
            AppBarCupertinoActionEntry(
              title: 'Delete',
              isDestructive: true,
              onAction: () {
                DialogHandler.showBaseDialog(
                  context: context,
                  dialogWidget: ConfirmationDialog(
                    title: 'Delete stream statistic',
                    isYesDestructive: true,
                    body:
                        'Are you sure you want to delete this stream statistic entry? This action can\'t be undone so be sure this is what you actually want!',
                    onOk: () {
                      pastStreamData.delete();
                      Navigator.of(context).pop();
                    },
                  ),
                );
              },
            ),
          ],
        ),
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
                .map((ram) => ram.round())
                .toList(),
            dataName: 'RAM',
            dataUnit: ' MB',
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
