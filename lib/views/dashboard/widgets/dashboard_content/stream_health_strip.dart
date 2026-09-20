import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../shared/design/design.dart';
import '../../../../stores/views/dashboard.dart';

/// One-line live-stream telemetry for the streaming-mode dashboard: bitrate,
/// encoder-dropped frames and CPU on the store's 1s stats cadence. Bare
/// status row (not a content card) with md side padding so it aligns with
/// the scene buttons below it. Renders placeholder dashes until a stream is
/// actually live - [DashboardStore.latestStreamStats] stays null otherwise.
class StreamHealthStrip extends StatelessWidget {
  static const double height = 32.0;

  const StreamHealthStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Observer(
          builder: (context) {
            final stats = GetIt.instance<DashboardStore>().latestStreamStats;
            final int? dropped = stats?.outputSkippedFrames;
            final int? total = stats?.outputTotalFrames;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _HealthValue(
                  label: 'kbit/s',
                  value: stats?.kbitsPerSec.toString() ?? '–',
                ),
                _HealthValue(
                  label: 'Dropped',
                  value: dropped == null || total == null || total == 0
                      ? '–'
                      : '$dropped (${(dropped / total * 100).toStringAsFixed(2)}%)',
                ),
                _HealthValue(
                  label: 'CPU',
                  value: stats != null
                      ? '${stats.cpuUsage.toStringAsFixed(1)}%'
                      : '–',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HealthValue extends StatelessWidget {
  final String label;
  final String value;

  const _HealthValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          this.label.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            color: textTheme.bodySmall!.color,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(this.value, style: textTheme.titleSmall),
      ],
    );
  }
}
