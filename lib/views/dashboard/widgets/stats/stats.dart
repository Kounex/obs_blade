import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../../../stores/views/dashboard.dart';
import 'formatted_text.dart';
import 'stats_container.dart';

class Stats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = Provider.of<DashboardStore>(context);

    return Center(
      child: Observer(builder: (_) {
        return Column(
          children: <Widget>[
            StatsContainer(
              title: 'Performance',
              children: [
                FormattedText(
                  label: 'FPS',
                  text: dashboardStore.streamStats?.fps?.round()?.toString(),
                ),
                FormattedText(
                  label: 'kBits / s',
                  text: dashboardStore.streamStats?.kbitsPerSec?.toString(),
                  width: 150.0,
                ),
                FormattedText(
                  label: 'Dropped Frames (%)',
                  text: dashboardStore.streamStats?.strain?.toString(),
                  width: 160.0,
                ),
              ],
            ),
            StatsContainer(
              title: 'Hardware',
              children: [
                FormattedText(
                  label: 'Missed Frames (render)',
                  text: dashboardStore.streamStats?.renderMissedFrames
                      ?.toString(),
                  width: 180.0,
                ),
                FormattedText(
                  label: 'Skipped Frames (encoder)',
                  text: dashboardStore.streamStats?.outputSkippedFrames
                      ?.toString(),
                  width: 200.0,
                ),
                FormattedText(
                  label: 'CPU Usage (%)',
                  text: dashboardStore.streamStats?.cpuUsage != null
                      ? ((dashboardStore.streamStats.cpuUsage * 100).round() /
                              100)
                          .toString()
                      : null,
                  width: 120.0,
                ),
                FormattedText(
                  label: 'Memory Usage (GB)',
                  text: dashboardStore.streamStats?.memoryUsage != null
                      ? (dashboardStore.streamStats.memoryUsage.round() / 1000)
                          .toString()
                      : null,
                  width: 155.0,
                ),
                FormattedText(
                  label: 'Free Disk Space GB',
                  text: dashboardStore.streamStats?.freeDiskSpace != null
                      ? (dashboardStore.streamStats.freeDiskSpace.round() /
                              1000)
                          .toString()
                      : null,
                  width: 165.0,
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}
