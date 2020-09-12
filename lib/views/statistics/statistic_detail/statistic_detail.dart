import 'package:flutter/material.dart';
import 'package:obs_blade/utils/modal_handler.dart';

import '../../../models/past_stream_data.dart';
import '../../../shared/dialogs/confirmation.dart';
import '../../../shared/dialogs/input.dart';
import '../../../shared/general/app_bar_cupertino_actions.dart';
import '../../../shared/general/formatted_text.dart';
import '../../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import '../../dashboard/widgets/stream_widgets/stats/stats_container.dart';
import 'widgets/stream_chart/stream_chart.dart';

class StatisticDetailView extends StatefulWidget {
  @override
  _StatisticDetailViewState createState() => _StatisticDetailViewState();
}

class _StatisticDetailViewState extends State<StatisticDetailView> {
  @override
  Widget build(BuildContext context) {
    PastStreamData pastStreamData = ModalRoute.of(context).settings.arguments;

    return Scaffold(
      body: TransculentCupertinoNavBarWrapper(
        previousTitle: 'Statistics',
        title: pastStreamData.name ?? 'Unnamed stream',
        actions: AppBarCupertinoActions(
          actionSheetTitle: 'Actions',
          actions: [
            AppBarCupertinoActionEntry(
                title: pastStreamData.starred != null && pastStreamData.starred
                    ? 'Delete from Favorites'
                    : 'Mark as Favorite',
                onAction: () {
                  if (pastStreamData.starred != null) {
                    pastStreamData.starred = !pastStreamData.starred;
                  } else {
                    pastStreamData.starred = true;
                  }
                  pastStreamData.box.put(pastStreamData.key, pastStreamData);
                  setState(() {});
                }),
            AppBarCupertinoActionEntry(
                title: 'Rename',
                onAction: () {
                  ModalHandler.showBaseDialog(
                    context: context,
                    dialogWidget: InputDialog(
                      title: 'Rename stream statistic',
                      body:
                          'Please enter the new name for this stream statistic',
                      inputPlaceholder: 'Statistics name',
                      inputText: pastStreamData.name,
                      onSave: (name) {
                        pastStreamData.name = name;
                        pastStreamData.save();

                        setState(() {});
                      },
                    ),
                  );
                }),
            AppBarCupertinoActionEntry(
              title: 'Delete',
              isDestructive: true,
              onAction: () {
                ModalHandler.showBaseDialog(
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
            data: pastStreamData.fpsList,
            dataTimesMS: pastStreamData.listEntryDateMS,
            dataName: 'FPS',
            chartColor: Colors.greenAccent,
            streamEndedMS: pastStreamData.listEntryDateMS.last,
            totalStreamTime: pastStreamData.totalStreamTime,
          ),
          Divider(),
          StreamChart(
            data: pastStreamData.cpuUsageList,
            dataTimesMS: pastStreamData.listEntryDateMS,
            amountFixedTooltipValue: 2,
            dataName: 'CPU Usage',
            dataUnit: '%',
            yMax: 100,
            chartColor: Colors.blueAccent,
            streamEndedMS: pastStreamData.listEntryDateMS.last,
            totalStreamTime: pastStreamData.totalStreamTime,
          ),
          Divider(),
          StreamChart(
            data: pastStreamData.kbitsPerSecList
                .map((kbits) => kbits.toDouble())
                .toList(),
            dataTimesMS: pastStreamData.listEntryDateMS,
            dataName: 'kbit/s',
            yPuffer: 1000,
            yInterval: 500,
            chartColor: Colors.orangeAccent,
            streamEndedMS: pastStreamData.listEntryDateMS.last,
            totalStreamTime: pastStreamData.totalStreamTime,
          ),
          Divider(),
          StreamChart(
            data: pastStreamData.memoryUsageList
                .map((memory) => memory / 1000)
                .toList(),
            dataTimesMS: pastStreamData.listEntryDateMS,
            amountFixedTooltipValue: 3,
            amountFixedYAxis: 1,
            dataName: 'RAM',
            dataUnit: ' GB',
            yPuffer: 0.5,
            yInterval: 0.2,
            chartColor: Colors.redAccent,
            streamEndedMS: pastStreamData.listEntryDateMS.last,
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
