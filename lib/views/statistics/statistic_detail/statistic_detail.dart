import 'package:flutter/material.dart';
import 'package:obs_blade/models/past_record_data.dart';

import '../../../models/past_stream_data.dart';
import '../../../shared/dialogs/confirmation.dart';
import '../../../shared/dialogs/input.dart';
import '../../../shared/general/app_bar_actions.dart';
import '../../../shared/general/base/card.dart';
import '../../../shared/general/formatted_text.dart';
import '../../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import '../../../types/extensions/int.dart';
import '../../../types/interfaces/past_stats_data.dart';
import '../../../utils/modal_handler.dart';
import '../../../utils/styling_helper.dart';
import '../../dashboard/widgets/obs_widgets/stats/stats_container.dart';
import '../widgets/stats_entry/stats_entry.dart';
import 'widgets/stats_chart.dart';

class StatisticDetailView extends StatefulWidget {
  const StatisticDetailView({
    super.key,
  });

  @override
  _StatisticDetailViewState createState() => _StatisticDetailViewState();
}

class _StatisticDetailViewState extends State<StatisticDetailView> {
  @override
  Widget build(BuildContext context) {
    PastStatsData pastStatsData =
        ModalRoute.of(context)!.settings.arguments as PastStatsData;

    List<StatsChart> streamCharts = [
      StatsChart(
        data: pastStatsData.fpsList,
        dataTimesMS: pastStatsData.listEntryDateMS,
        dataName: 'FPS',
        chartColor: Colors.greenAccent,
        streamEndedMS: pastStatsData.listEntryDateMS.last,
        totalTime: pastStatsData.totalTime!,
      ),
      StatsChart(
        data: pastStatsData.cpuUsageList,
        dataTimesMS: pastStatsData.listEntryDateMS,
        amountFixedTooltipValue: 2,
        dataName: 'CPU Usage',
        dataUnit: '%',
        yMax: 100,
        chartColor: Colors.blueAccent,
        streamEndedMS: pastStatsData.listEntryDateMS.last,
        totalTime: pastStatsData.totalTime!,
      ),
      StatsChart(
        data: pastStatsData.kbitsPerSecList
            .map((kbits) => kbits.toDouble())
            .toList(),
        dataTimesMS: pastStatsData.listEntryDateMS,
        dataName: 'kbit/s',
        minYInterval: 250,
        chartColor: Colors.orangeAccent,
        streamEndedMS: pastStatsData.listEntryDateMS.last,
        totalTime: pastStatsData.totalTime!,
      ),
      StatsChart(
        data: pastStatsData.memoryUsageList
            .map((memory) => memory / 1000)
            .toList(),
        dataTimesMS: pastStatsData.listEntryDateMS,
        amountFixedTooltipValue: 3,
        amountFixedYAxis: 1,
        dataName: 'Memory Usage',
        dataUnit: ' GB',
        minYInterval: 0.1,
        chartColor: Colors.redAccent,
        streamEndedMS: pastStatsData.listEntryDateMS.last,
        totalTime: pastStatsData.totalTime!,
      ),
    ];

    return Scaffold(
      body: TransculentCupertinoNavBarWrapper(
        previousTitle: 'Statistics',
        title: 'Details',
        actions: AppBarActions(
          actions: [
            AppBarActionEntry(
                title: pastStatsData.starred != null && pastStatsData.starred!
                    ? 'Delete from Favorites'
                    : 'Mark as Favorite',
                onAction: () {
                  if (pastStatsData.starred != null) {
                    pastStatsData.starred = !pastStatsData.starred!;
                  } else {
                    pastStatsData.starred = true;
                  }
                  if (pastStatsData is PastStreamData) {
                    pastStatsData.box!.put(pastStatsData.key, pastStatsData);
                  } else if (pastStatsData is PastRecordData) {
                    pastStatsData.box!.put(pastStatsData.key, pastStatsData);
                  }
                  setState(() {});
                }),
            AppBarActionEntry(
                title: 'Rename',
                onAction: () {
                  ModalHandler.showBaseDialog(
                    context: context,
                    dialogWidget: InputDialog(
                      title: 'Rename entry',
                      body: 'Please enter a new name for this entry',
                      inputPlaceholder: 'Entry name',
                      inputText: pastStatsData.name,
                      onSave: (name) {
                        pastStatsData.name = name;
                        if (pastStatsData is PastStreamData) {
                          pastStatsData.save();
                        } else if (pastStatsData is PastRecordData) {
                          pastStatsData.save();
                        }

                        setState(() {});
                      },
                    ),
                  );
                }),
            AppBarActionEntry(
              title: 'Delete',
              isDestructive: true,
              onAction: () {
                ModalHandler.showBaseDialog(
                  context: context,
                  dialogWidget: ConfirmationDialog(
                    title: 'Delete entry',
                    isYesDestructive: true,
                    body:
                        'Are you sure you want to delete this entry? This action can\'t be undone so be sure this is what you actually want!',
                    onOk: (_) {
                      if (pastStatsData is PastStreamData) {
                        pastStatsData.delete();
                      } else if (pastStatsData is PastRecordData) {
                        pastStatsData.delete();
                      }
                      Navigator.of(context).pop();
                    },
                  ),
                );
              },
            ),
          ],
        ),
        listViewChildren: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kBaseCardMaxWidth),
              child: Column(
                children: [
                  BaseCard(
                    child: StatsEntry(
                      pastStatsData: pastStatsData,
                      usedInDetail: true,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 12,
                      left: 16.0,
                      right: 16.0,
                      bottom: 30.0,
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      runSpacing: 30.0,
                      spacing: 30.0,
                      children: streamCharts
                          .map(
                            (streamChart) => ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: StylingHelper.max_width_mobile /
                                    (MediaQuery.sizeOf(context).width <
                                            StylingHelper.max_width_mobile
                                        ? 1
                                        : 2),
                              ),
                              child: BaseCard(
                                topPadding: 0,
                                rightPadding: 0,
                                bottomPadding: 0,
                                leftPadding: 0,
                                paddingChild: const EdgeInsets.all(0),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0) +
                                      const EdgeInsets.only(
                                        top: 4.0,
                                        left: 20.0,
                                        right: 24.0,
                                      ),
                                  child: streamChart,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  StatsContainer(
                    title: 'Some numbers',
                    children: [
                      FormattedText(
                        label: 'Session Time',
                        text: pastStatsData.totalTime!
                            .secondsToFormattedDurationString(),
                        width: 100.0,
                      ),
                      FormattedText(
                        label: 'Average FPS',
                        text: (pastStatsData.fpsList.reduce((a, b) => a + b) /
                                pastStatsData.fpsList.length)
                            .toStringAsFixed(2),
                        width: 75.0,
                      ),
                      FormattedText(
                        label: 'Average CPU Usage',
                        text: (pastStatsData.cpuUsageList
                                    .reduce((a, b) => a + b) /
                                pastStatsData.cpuUsageList.length)
                            .toStringAsFixed(2),
                        unit: '%',
                        width: 115.0,
                      ),
                      FormattedText(
                        label: 'Average kbit/s',
                        text: (pastStatsData.kbitsPerSecList
                                    .reduce((a, b) => a + b) /
                                pastStatsData.kbitsPerSecList.length)
                            .toStringAsFixed(2),
                        width: 85.0,
                      ),
                      FormattedText(
                        label: 'Average Memory Usage',
                        text: ((pastStatsData.memoryUsageList
                                        .reduce((a, b) => a + b) /
                                    pastStatsData.memoryUsageList.length) /
                                1000)
                            .toStringAsFixed(2),
                        unit: ' GB',
                        width: 140.0,
                      ),
                      FormattedText(
                        label: 'Total Output Frames',
                        text: pastStatsData.outputTotalFrames.toString(),
                        width: 120.0,
                      ),
                      FormattedText(
                        label: 'Skipped Output Frames',
                        text: pastStatsData.outputSkippedFrames.toString(),
                        width: 140.0,
                      ),
                      FormattedText(
                        label: 'Total Render Frames',
                        text: pastStatsData.renderTotalFrames.toString(),
                        width: 120.0,
                      ),
                      FormattedText(
                        label: 'Skipped Render Frames',
                        text: pastStatsData.renderSkippedFrames.toString(),
                        width: 140.0,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
