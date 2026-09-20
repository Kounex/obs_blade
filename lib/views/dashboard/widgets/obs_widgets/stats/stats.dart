import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/general/question_mark_tooltip.dart';
import 'package:obs_blade/types/extensions/int.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../../shared/animator/status_dot.dart';
import '../../../../../shared/design/design.dart';
import '../../../../../stores/views/dashboard.dart';
import 'stat_tile.dart';
import 'stats_container.dart';

class Stats extends StatefulWidget {
  final EdgeInsets? pageIndicatorPadding;

  /// Phone behavior: the section sizes itself to the tallest measured stat
  /// page instead of occupying a fixed frame (the fixed 650px frame left
  /// large dead areas below the shorter pages)
  final bool autoHeight;

  const Stats({super.key, this.pageIndicatorPadding, this.autoHeight = false});

  @override
  _StatsState createState() => _StatsState();
}

class _StatsState extends State<Stats> {
  final PageController _pageController = PageController();

  /// Measured content height per stat page (autoHeight mode) - the section
  /// takes the max so the frame never changes while swiping
  final Map<int, double> _pageHeights = {};

  void _reportPageHeight(int page, double height) {
    if (this.widget.autoHeight &&
        _pageHeights[page] != height &&
        this.mounted) {
      setState(() => _pageHeights[page] = height);
    }
  }

  double get _autoHeight =>
      _pageHeights.isEmpty ? 320.0 : _pageHeights.values.reduce(math.max);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding:
              this.widget.pageIndicatorPadding ??
              const EdgeInsets.only(top: AppSpacing.md),
          child: SmoothPageIndicator(
            controller: _pageController,
            count: 3,
            effect: ScrollingDotsEffect(
              activeDotColor: Theme.of(context).colorScheme.secondary,
              dotColor: Theme.of(context).dividerColor,
              dotHeight: 10.0,
              dotWidth: 10.0,
            ),
          ),
        ),
        if (this.widget.autoHeight)
          SizedBox(
            height: _autoHeight,
            child: Observer(builder: (context) => _buildPageView()),
          )
        else
          Expanded(child: Observer(builder: (context) => _buildPageView())),
      ],
    );
  }

  Widget _buildPageView() {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();
    final AppStatusColors statusColors = Theme.of(
      context,
    ).extension<AppStatusColors>()!;

    return PageView(
      controller: _pageController,

      /// Builds the adjacent page ahead of the swipe - doubles as early
      /// height measurement for [autoHeight]
      allowImplicitScrolling: true,
      children: <Widget>[
        _reportingPage(
          0,
          StatsContainer(
            title: 'OBS Stats',
            trailing: const QuestionMarkTooltip(
              message:
                  'Stats marked with * are stats of OBS and not your computer.',
            ),
            child: StatTileGrid(
              tiles: [
                StatTile(
                  label: 'FPS',
                  text: dashboardStore.latestOBSStats?.activeFps
                      .round()
                      .toString(),
                ),
                StatTile(
                  label: 'CPU*',
                  unit: '%',
                  text: dashboardStore.latestOBSStats?.cpuUsage != null
                      ? (dashboardStore.latestOBSStats!.cpuUsage)
                            .toStringAsFixed(2)
                      : null,
                  width: 75.0,
                ),
                StatTile(
                  label: 'Memory Usage*',
                  unit: ' GB',
                  text: dashboardStore.latestOBSStats?.memoryUsage != null
                      ? (dashboardStore.latestOBSStats!.memoryUsage / 1000)
                            .toStringAsFixed(2)
                      : null,
                  width: 100.0,
                ),
                StatTile(
                  label: 'Available Disk Space',
                  unit: ' GB',
                  text:
                      dashboardStore.latestOBSStats?.availableDiskSpace != null
                      ? (dashboardStore.latestOBSStats!.availableDiskSpace /
                                1000)
                            .toStringAsFixed(2)
                      : null,
                  width: 120.0,
                ),
                StatTile(
                  label: 'Average Frame Render Time',
                  unit: ' ms',
                  text: dashboardStore.latestOBSStats?.averageFrameRenderTime
                      .toStringAsFixed(2),
                  width: 160.0,
                ),
                StatTile(
                  label: 'Total Render Frames',
                  text: dashboardStore.latestOBSStats?.renderTotalFrames
                      .toString(),
                  width: 120.0,
                ),
                StatTile(
                  label: 'Skipped Render Frames',
                  text: dashboardStore.latestOBSStats?.renderSkippedFrames
                      .toString(),
                  width: 140.0,
                ),
              ],
            ),
          ),
        ),
        _reportingPage(
          1,
          StatsContainer(
            title: 'Stream',
            titleLeading: dashboardStore.isLive
                ? StatusDot(size: 8.0, color: statusColors.live)
                : null,
            child: StatTileGrid(
              tiles: [
                StatTile(
                  label: 'Session Time',
                  text: dashboardStore.latestStreamStats?.totalTime
                      .secondsToFormattedDurationString(),
                  width: 100,
                ),
                StatTile(
                  label: 'kbit/s',
                  text: dashboardStore.latestStreamStats?.kbitsPerSec
                      .toString(),
                  width: 80,
                ),
                StatTile(
                  label: 'Total Output Frames',
                  text: dashboardStore.latestStreamStats?.outputTotalFrames
                      .toString(),
                  width: 120.0,
                ),
                StatTile(
                  label: 'Skipped Output Frames',
                  text: dashboardStore.latestStreamStats?.outputSkippedFrames
                      .toString(),
                  width: 135.0,
                ),
                StatTile(
                  label: 'Total Render Frames',
                  text: dashboardStore.latestStreamStats?.renderTotalFrames
                      .toString(),
                  width: 120.0,
                ),
                StatTile(
                  label: 'Skipped Render Frames',
                  text: dashboardStore.latestStreamStats?.renderSkippedFrames
                      .toString(),
                  width: 135.0,
                ),
              ],
            ),
          ),
        ),
        _reportingPage(
          2,
          StatsContainer(
            title: 'Recording',
            titleLeading: dashboardStore.isRecording
                ? StatusDot(size: 8.0, color: statusColors.recording)
                : null,
            child: StatTileGrid(
              tiles: [
                StatTile(
                  label: 'Session Time',
                  text: dashboardStore.latestRecordStats?.totalTime
                      .secondsToFormattedDurationString(),
                  width: 100,
                ),
                StatTile(
                  label: 'kbit/s',
                  text: dashboardStore.latestRecordStats?.kbitsPerSec
                      .toString(),
                  width: 80,
                ),
                StatTile(
                  label: 'Total Output Frames',
                  text: dashboardStore.isRecording
                      ? dashboardStore.latestRecordStats?.outputTotalFrames
                            .toString()
                      : null,
                  width: 120.0,
                ),
                StatTile(
                  label: 'Skipped Output Frames',
                  text: dashboardStore.isRecording
                      ? dashboardStore.latestRecordStats?.outputSkippedFrames
                            .toString()
                      : null,
                  width: 135.0,
                ),
                StatTile(
                  label: 'Total Render Frames',
                  text: dashboardStore.isRecording
                      ? dashboardStore.latestRecordStats?.renderTotalFrames
                            .toString()
                      : null,
                  width: 120.0,
                ),
                StatTile(
                  label: 'Skipped Render Frames',
                  text: dashboardStore.isRecording
                      ? dashboardStore.latestRecordStats?.renderSkippedFrames
                            .toString()
                      : null,
                  width: 135.0,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _reportingPage(int index, Widget child) {
    return SingleChildScrollView(
      /// No vertical scrolling inside a stat page - a plain card. The
      /// clamping scroll view used to eat the dashboard's vertical drag
      /// gesture even with nothing to scroll.
      physics: const NeverScrollableScrollPhysics(),
      child: _SizeReportingWidget(
        onSize: (size) => _reportPageHeight(index, size.height),
        child: child,
      ),
    );
  }
}

/// Reports its child's laid-out size after every layout - used by [Stats]
/// to size the page viewport to the tallest measured page
class _SizeReportingWidget extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onSize;

  const _SizeReportingWidget({required this.onSize, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSizeReporter(onSize);
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onSize);

  final ValueChanged<Size> onSize;

  @override
  void performLayout() {
    super.performLayout();
    final Size newSize = this.child?.size ?? this.size;
    WidgetsBinding.instance.addPostFrameCallback((_) => this.onSize(newSize));
  }
}
