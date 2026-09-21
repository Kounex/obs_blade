import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../shared/design/design.dart';
import '../../../../stores/views/dashboard.dart';

/// Floating live-stream telemetry pill for the streaming-mode dashboard:
/// bitrate, encoder-dropped frames and CPU on the store's 1s stats cadence,
/// overlaid on the scene preview (toggled by the floating chart button) so
/// it costs no layout space. Dark translucent surface + hairline (the
/// cockpit's floating-chrome idiom) - it floats over arbitrary video
/// content, so the text stays white regardless of theme.
/// Shows a single "Not streaming" label while
/// [DashboardStore.latestStreamStats] is null, and swaps to the
/// "LAST KNOWN STATE" marker (dimmed, never asserting frozen telemetry)
/// while [DashboardStore.obsStateStale].
class StreamHealthPill extends StatelessWidget {
  const StreamHealthPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: AppRadius.pill,
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
        ),
      ),
      child: Observer(
        builder: (context) {
          final DashboardStore dashboardStore =
              GetIt.instance<DashboardStore>();
          final stats = dashboardStore.latestStreamStats;
          const TextStyle style = TextStyle(
            color: Colors.white,
            fontSize: 12.0,
          );

          return AnimatedSwitcher(
            duration: AppMotion.medium,
            child: dashboardStore.obsStateStale
                ? Row(
                    key: const ValueKey('stale'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.exclamationmark_circle,
                        size: 14.0,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'LAST KNOWN STATE - reconnecting to OBS',
                        style: style.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  )
                : stats == null
                ? Text(
                    key: const ValueKey('idle'),
                    'Not streaming',
                    style: style.copyWith(color: Colors.white70),
                  )
                : Row(
                    key: const ValueKey('live'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CountUpText(value: '${stats.kbitsPerSec}', style: style),
                      Text(' kbit/s', style: style),
                      const SizedBox(width: AppSpacing.md),
                      Text('Dropped ', style: style),
                      CountUpText(
                        value: '${stats.outputSkippedFrames}',
                        style: style,
                      ),
                      if (stats.outputTotalFrames != 0)
                        Text(
                          ' (${(stats.outputSkippedFrames / stats.outputTotalFrames * 100).toStringAsFixed(2)}%)',
                          style: style,
                        ),
                      const SizedBox(width: AppSpacing.md),
                      Text('CPU ', style: style),
                      CountUpText(
                        value: stats.cpuUsage.toStringAsFixed(1),
                        style: style,
                      ),
                      Text('%', style: style),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
