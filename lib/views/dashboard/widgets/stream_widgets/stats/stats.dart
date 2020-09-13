import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:obs_blade/utils/styling_helper.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../../stores/views/dashboard.dart';
import '../../../../../shared/general/formatted_text.dart';
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
            padding: widget.pageIndicatorPadding ??
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
                        label: 'FPS',
                        text: dashboardStore.latestStreamStats?.fps
                            ?.round()
                            ?.toString(),
                      ),
                      FormattedText(
                        label: 'kBits / s',
                        text: dashboardStore.latestStreamStats?.kbitsPerSec
                            ?.toString(),
                        width: 150.0,
                      ),
                      FormattedText(
                        label: 'Dropped Frames (%)',
                        text: dashboardStore.latestStreamStats?.strain
                            ?.toString(),
                        width: 160.0,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width,
                  child: StatsContainer(
                    title: 'Hardware',
                    children: [
                      FormattedText(
                        label: 'Missed Frames (render)',
                        text: dashboardStore
                            .latestStreamStats?.renderMissedFrames
                            ?.toString(),
                        width: 180.0,
                      ),
                      FormattedText(
                        label: 'Skipped Frames (encoder)',
                        text: dashboardStore
                            .latestStreamStats?.outputSkippedFrames
                            ?.toString(),
                        width: 200.0,
                      ),
                      FormattedText(
                        label: 'CPU Usage (%)',
                        text: dashboardStore.latestStreamStats?.cpuUsage != null
                            ? ((dashboardStore.latestStreamStats.cpuUsage * 100)
                                        .round() /
                                    100)
                                .toString()
                            : null,
                        width: 120.0,
                      ),
                      FormattedText(
                        label: 'Memory Usage (GB)',
                        text: dashboardStore.latestStreamStats?.memoryUsage !=
                                null
                            ? (dashboardStore.latestStreamStats.memoryUsage
                                        .round() /
                                    1000)
                                .toString()
                            : null,
                        width: 155.0,
                      ),
                      FormattedText(
                        label: 'Free Disk Space GB',
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
