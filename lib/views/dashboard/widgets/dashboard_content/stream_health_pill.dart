import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../shared/design/design.dart';
import '../../../../stores/views/dashboard.dart';

/// Floating live-stream telemetry pill for the streaming-mode dashboard:
/// bitrate, encoder-dropped frames and CPU on the store's 1s stats cadence,
/// overlaid on the scene preview (toggled by the floating chart button) so
/// it costs no layout space. Dark translucent surface - it floats over
/// arbitrary video content, so the text stays white regardless of theme.
/// Shows a single "Not streaming" label while
/// [DashboardStore.latestStreamStats] is null.
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
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Observer(
        builder: (context) {
          final stats = GetIt.instance<DashboardStore>().latestStreamStats;
          const TextStyle style = TextStyle(
            color: Colors.white,
            fontSize: 12.0,
          );

          if (stats == null) {
            return Text(
              'Not streaming',
              style: style.copyWith(color: Colors.white70),
            );
          }

          final int dropped = stats.outputSkippedFrames;
          final int total = stats.outputTotalFrames;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${stats.kbitsPerSec} kbit/s', style: style),
              const SizedBox(width: AppSpacing.md),
              Text(
                total == 0
                    ? 'Dropped $dropped'
                    : 'Dropped $dropped (${(dropped / total * 100).toStringAsFixed(2)}%)',
                style: style,
              ),
              const SizedBox(width: AppSpacing.md),
              Text('CPU ${stats.cpuUsage.toStringAsFixed(1)}%', style: style),
            ],
          );
        },
      ),
    );
  }
}
