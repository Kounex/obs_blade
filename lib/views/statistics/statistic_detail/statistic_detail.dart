import 'package:flutter/material.dart';
import 'package:obs_blade/models/past_record_data.dart';

import '../../../models/past_stream_data.dart';
import '../../../shared/design/design.dart';
import '../../../shared/dialogs/confirmation.dart';
import '../../../shared/dialogs/input.dart';
import '../../../shared/general/app_bar_actions.dart';
import '../../../shared/general/base/card.dart';
import '../../../shared/general/base/constrained_box.dart';
import '../../../shared/general/base/icon_button.dart';
import '../../../shared/general/responsive_widget_wrapper.dart';
import '../../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import '../../../types/extensions/int.dart';
import '../../../types/extensions/list.dart';
import '../../../types/interfaces/past_stats_data.dart';
import '../../../utils/modal_handler.dart';
import '../../dashboard/widgets/obs_widgets/stats/stats_container.dart';
import '../widgets/stats_entry/stats_entry.dart';
import 'widgets/stat_tile.dart';
import 'widgets/stats_chart.dart';

class StatisticDetailView extends StatefulWidget {
  const StatisticDetailView({super.key});

  @override
  _StatisticDetailViewState createState() => _StatisticDetailViewState();
}

class _StatisticDetailViewState extends State<StatisticDetailView> {
  void _toggleFavorite(PastStatsData pastStatsData) {
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
  }

  @override
  Widget build(BuildContext context) {
    PastStatsData pastStatsData =
        ModalRoute.of(context)!.settings.arguments as PastStatsData;

    final bool isStarred =
        pastStatsData.starred != null && pastStatsData.starred!;

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
        actions: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BaseIconButton(
              icon: isStarred ? Icons.star : Icons.star_border,
              backgroundColor: Colors.transparent,
              foregroundColor: isStarred
                  ? Theme.of(context).extension<AppStatusColors>()!.favorite
                  : Theme.of(context).extension<AppTextColors>()!.textOrnament,
              onTap: () => _toggleFavorite(pastStatsData),
            ),
            AppBarActions(
              actions: [
                AppBarActionEntry(
                  title: isStarred
                      ? 'Delete from Favorites'
                      : 'Mark as Favorite',
                  onAction: () => _toggleFavorite(pastStatsData),
                ),
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
                  },
                ),
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
          ],
        ),
        listViewChildren: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kWideContentMaxWidth),
              child: Column(
                children: [
                  StaggeredEntrance(
                    scaleFrom: 0.985,
                    child: BaseCard(
                      maxWidth: kWideContentMaxWidth,
                      child: StatsEntry(
                        pastStatsData: pastStatsData,
                        usedInDetail: true,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.md,
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      bottom: AppSpacing.xxl,
                    ),
                    child: ResponsiveWidgetWrapper(
                      mobileWidget: StatsChartGrid(charts: streamCharts),
                      tabletWidget: StatsChartGrid(
                        charts: streamCharts,
                        columns: 2,
                      ),
                    ),
                  ),
                  StaggeredEntrance(
                    scaleFrom: 0.985,
                    index: streamCharts.length + 1,
                    child: StatsContainer(
                      maxWidth: kWideContentMaxWidth,
                      title: 'Some numbers',
                      child: StatTileGrid(
                        tiles: [
                          StatTile(
                            label: 'Session Time',
                            value: pastStatsData.totalTime!
                                .secondsToFormattedDurationString(),
                          ),
                          StatTile(
                            label: 'Average FPS',
                            value:
                                (pastStatsData.fpsList.reduce((a, b) => a + b) /
                                        pastStatsData.fpsList.length)
                                    .toStringAsFixed(2),
                            valueColor: Colors.greenAccent,
                            width: 80.0,
                          ),
                          StatTile(
                            label: 'Average CPU Usage',
                            value:
                                (pastStatsData.cpuUsageList.reduce(
                                          (a, b) => a + b,
                                        ) /
                                        pastStatsData.cpuUsageList.length)
                                    .toStringAsFixed(2),
                            unit: '%',
                            valueColor: Colors.blueAccent,
                          ),
                          StatTile(
                            label: 'Average kbit/s',
                            value:
                                (pastStatsData.kbitsPerSecList.reduce(
                                          (a, b) => a + b,
                                        ) /
                                        pastStatsData.kbitsPerSecList.length)
                                    .toStringAsFixed(2),
                            valueColor: Colors.orangeAccent,
                          ),
                          StatTile(
                            label: 'Average Memory Usage',
                            value:
                                ((pastStatsData.memoryUsageList.reduce(
                                              (a, b) => a + b,
                                            ) /
                                            pastStatsData
                                                .memoryUsageList
                                                .length) /
                                        1000)
                                    .toStringAsFixed(2),
                            unit: ' GB',
                            valueColor: Colors.redAccent,
                            width: 110.0,
                          ),
                          StatTile(
                            label: 'Total Output Frames',
                            value: pastStatsData.outputTotalFrames.toString(),
                            width: 120.0,
                          ),
                          StatTile(
                            label: 'Skipped Output Frames',
                            value: pastStatsData.outputSkippedFrames.toString(),
                            width: 135.0,
                          ),
                          StatTile(
                            label: 'Total Render Frames',
                            value: pastStatsData.renderTotalFrames.toString(),
                            width: 120.0,
                          ),
                          StatTile(
                            label: 'Skipped Render Frames',
                            value: pastStatsData.renderSkippedFrames.toString(),
                            width: 135.0,
                          ),
                        ],
                      ),
                    ),
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

/// The detail's chart cards: [columns] per row, each sized from the
/// available width (a fixed card width can't know how much room the
/// constrained column leaves after padding + spacing). Drops to one
/// column when a card would get narrower than [minChartWidth].
class StatsChartGrid extends StatelessWidget {
  static const double minChartWidth = 300.0;

  final List<StatsChart> charts;
  final int columns;

  const StatsChartGrid({super.key, required this.charts, this.columns = 1});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = this.columns;
        while (columns > 1 &&
            (constraints.maxWidth - (columns - 1) * AppSpacing.xl) / columns <
                minChartWidth) {
          columns--;
        }
        final double width =
            (constraints.maxWidth - (columns - 1) * AppSpacing.xl) / columns;

        return Wrap(
          runSpacing: AppSpacing.xl,
          spacing: AppSpacing.xl,
          children: this.charts.mapIndexed((chart, index) {
            return StaggeredEntrance(
              scaleFrom: 0.985,
              index: index + 1,
              child: SizedBox(
                width: width,
                child: BaseCard(
                  constrained: false,
                  topPadding: 0,
                  rightPadding: 0,
                  bottomPadding: 0,
                  leftPadding: 0,
                  paddingChild: const EdgeInsets.all(0),
                  child: Padding(
                    padding:
                        const EdgeInsets.all(AppSpacing.md) +
                        const EdgeInsets.only(
                          top: AppSpacing.xs,
                          left: AppSpacing.xl,
                          right: AppSpacing.xl,
                        ),
                    child: chart,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
