import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/general/question_mark_tooltip.dart';
import 'package:obs_blade/types/extensions/int.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../../shared/general/formatted_text.dart';
import '../../../../../stores/views/dashboard.dart';
import 'stats_container.dart';

class Stats extends StatefulWidget {
  final EdgeInsets? pageIndicatorPadding;

  const Stats({Key? key, this.pageIndicatorPadding}) : super(key: key);

  @override
  _StatsState createState() => _StatsState();
}

class _StatsState extends State<Stats> {
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    return Column(
      children: [
        Padding(
          padding: this.widget.pageIndicatorPadding ??
              const EdgeInsets.only(
                top: 12.0,
              ),
          child: SmoothPageIndicator(
            controller: _pageController,
            count: 3,
            effect: ScrollingDotsEffect(
              activeDotColor: Theme.of(context)
                  .switchTheme
                  .trackColor!
                  .resolve({MaterialState.selected})!,
              dotHeight: 10.0,
              dotWidth: 10.0,
            ),
          ),
        ),
        Expanded(
          child: Observer(builder: (_) {
            return PageView(
              controller: _pageController,
              children: <Widget>[
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: StatsContainer(
                    elevation: 0.0,
                    title: 'OBS Stats',
                    trailing: const QuestionMarkTooltip(
                        message:
                            'Stats marked with * are stats of OBS and not your computer.'),
                    children: [
                      FormattedText(
                        label: 'FPS',
                        text: dashboardStore.latestOBSStats?.activeFps
                            .round()
                            .toString(),
                      ),
                      FormattedText(
                        label: 'CPU*',
                        unit: '%',
                        text: dashboardStore.latestOBSStats?.cpuUsage != null
                            ? (dashboardStore.latestOBSStats!.cpuUsage)
                                .toStringAsFixed(2)
                            : null,
                        width: 75.0,
                      ),
                      FormattedText(
                        label: 'Memory Usage*',
                        unit: ' GB',
                        text: dashboardStore.latestOBSStats?.memoryUsage != null
                            ? (dashboardStore.latestOBSStats!.memoryUsage /
                                    1000)
                                .toStringAsFixed(2)
                            : null,
                        width: 100.0,
                      ),
                      FormattedText(
                        label: 'Available Disk Space',
                        unit: ' GB',
                        text:
                            dashboardStore.latestOBSStats?.availableDiskSpace !=
                                    null
                                ? (dashboardStore.latestOBSStats!
                                            .availableDiskSpace /
                                        1000)
                                    .toStringAsFixed(2)
                                : null,
                        width: 120.0,
                      ),
                      FormattedText(
                        label: 'Average Frame Render Time',
                        unit: ' milliseconds',
                        text: dashboardStore
                            .latestOBSStats?.averageFrameRenderTime
                            .toStringAsFixed(4),
                        width: 160.0,
                      ),
                      FormattedText(
                        label: 'Total Render Frames',
                        text: dashboardStore.latestOBSStats?.renderTotalFrames
                            .toString(),
                        width: 120.0,
                      ),
                      FormattedText(
                        label: 'Skipped Render Frames',
                        text: dashboardStore.latestOBSStats?.renderSkippedFrames
                            .toString(),
                        width: 140.0,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: StatsContainer(
                    elevation: 0.0,
                    title: 'Stream',
                    children: [
                      FormattedText(
                        label: 'Session Time',
                        text: dashboardStore.latestStreamStats?.totalTime
                            .secondsToFormattedDurationString(),
                        width: 100,
                      ),
                      FormattedText(
                        label: 'kbit/s',
                        text: dashboardStore.latestStreamStats?.kbitsPerSec
                            .toString(),
                        width: 80,
                      ),
                      FormattedText(
                        label: 'Total Output Frames',
                        text: dashboardStore
                            .latestStreamStats?.outputTotalFrames
                            .toString(),
                        width: 120.0,
                      ),
                      FormattedText(
                        label: 'Skipped Output Frames',
                        text: dashboardStore
                            .latestStreamStats?.outputSkippedFrames
                            .toString(),
                        width: 135.0,
                      ),
                      FormattedText(
                        label: 'Total Render Frames',
                        text: dashboardStore
                            .latestStreamStats?.renderTotalFrames
                            .toString(),
                        width: 120.0,
                      ),
                      FormattedText(
                        label: 'Skipped Render Frames',
                        text: dashboardStore
                            .latestStreamStats?.renderSkippedFrames
                            .toString(),
                        width: 135.0,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: StatsContainer(
                    elevation: 0.0,
                    title: 'Recording',
                    children: [
                      FormattedText(
                        label: 'Session Time',
                        text: dashboardStore.latestRecordStats?.totalTime
                            .secondsToFormattedDurationString(),
                        width: 100,
                      ),
                      FormattedText(
                        label: 'kbit/s',
                        text: dashboardStore.latestRecordStats?.kbitsPerSec
                            .toString(),
                        width: 80,
                      ),
                      FormattedText(
                        label: 'Total Output Frames',
                        text: dashboardStore.isRecording
                            ? dashboardStore
                                .latestRecordStats?.outputTotalFrames
                                .toString()
                            : null,
                        width: 120.0,
                      ),
                      FormattedText(
                        label: 'Skipped Output Frames',
                        text: dashboardStore.isRecording
                            ? dashboardStore
                                .latestRecordStats?.outputSkippedFrames
                                .toString()
                            : null,
                        width: 135.0,
                      ),
                      FormattedText(
                        label: 'Total Render Frames',
                        text: dashboardStore.isRecording
                            ? dashboardStore
                                .latestRecordStats?.renderTotalFrames
                                .toString()
                            : null,
                        width: 120.0,
                      ),
                      FormattedText(
                        label: 'Skipped Render Frames',
                        text: dashboardStore.isRecording
                            ? dashboardStore
                                .latestRecordStats?.renderSkippedFrames
                                .toString()
                            : null,
                        width: 135.0,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}
