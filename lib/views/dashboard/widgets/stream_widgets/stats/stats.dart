import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../../types/extensions/int.dart';
import '../../../../../shared/general/formatted_text.dart';
import '../../../../../stores/views/dashboard.dart';
import 'stats_container.dart';

class Stats extends StatefulWidget {
  final EdgeInsets pageIndicatorPadding;

  Stats({this.pageIndicatorPadding});

  @override
  _StatsState createState() => _StatsState();
}

class _StatsState extends State<Stats> {
  ScrollController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = Provider.of<DashboardStore>(context);

    return Observer(builder: (_) {
      // TODO: making this as a carousel just like saved connection if mobile, wrap on tablet
      return Column(
        children: [
          Padding(
            padding: this.widget.pageIndicatorPadding ??
                EdgeInsets.only(
                  top: 12.0,
                ),
            child: SmoothPageIndicator(
              controller: _pageController,
              count: 2,
              effect: ScrollingDotsEffect(
                activeDotColor: Theme.of(context).toggleableActiveColor,
                dotHeight: 10.0,
                dotWidth: 10.0,
              ),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              children: <Widget>[
                Container(
                  width: MediaQuery.of(context).size.width,
                  child: StatsContainer(
                    title: 'Performance',
                    children: [
                      FormattedText(
                        label: 'Total stream time',
                        text: dashboardStore.latestStreamStats?.totalStreamTime
                            ?.secondsToFormattedDurationString(),
                        width: 100.0,
                      ),
                      FormattedText(
                        label: 'FPS',
                        text: dashboardStore.latestStreamStats?.fps
                            ?.round()
                            ?.toString(),
                      ),
                      FormattedText(
                        label: 'kbit/s',
                        text: dashboardStore.latestStreamStats?.kbitsPerSec
                            ?.toString(),
                        width: 75.0,
                      ),
                      FormattedText(
                        label: 'CPU Usage',
                        unit: '%',
                        text: dashboardStore.latestStreamStats?.cpuUsage
                            ?.toStringAsFixed(2),
                        width: 70.0,
                      ),
                      FormattedText(
                        label: 'Memory Usage',
                        unit: ' GB',
                        text: dashboardStore.latestStreamStats?.memoryUsage !=
                                null
                            ? (dashboardStore.latestStreamStats.memoryUsage /
                                    1000)
                                .toStringAsFixed(2)
                            : null,
                        width: 90.0,
                      ),
                      FormattedText(
                        label: 'Dropped Frames',
                        unit: '%',
                        text: dashboardStore.latestStreamStats?.strain
                            ?.toString(),
                        width: 95.0,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width,
                  child: StatsContainer(
                    title: 'Misc.',
                    children: [
                      FormattedText(
                        label: 'Missed Frames (render)',
                        text: dashboardStore
                            .latestStreamStats?.renderMissedFrames
                            ?.toStringAsFixed(2),
                        width: 135.0,
                      ),
                      FormattedText(
                        label: 'Skipped Frames (encoder)',
                        text: dashboardStore
                            .latestStreamStats?.outputSkippedFrames
                            ?.toString(),
                        width: 150.0,
                      ),
                      FormattedText(
                        label: 'Total Output Frames (encoder)',
                        text: dashboardStore
                            .latestStreamStats?.outputTotalFrames
                            ?.toString(),
                        width: 175.0,
                      ),
                      FormattedText(
                        label: 'Total Output Frames (render)',
                        text: dashboardStore
                            .latestStreamStats?.renderTotalFrames
                            ?.toString(),
                        width: 165.0,
                      ),
                      FormattedText(
                        label: 'Free Disk Space',
                        unit: ' GB',
                        text: dashboardStore.latestStreamStats?.freeDiskSpace !=
                                null
                            ? (dashboardStore.latestStreamStats.freeDiskSpace
                                        .round() /
                                    1000)
                                .toString()
                            : null,
                        width: 165.0,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
