import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/animator/status_dot.dart';
import 'package:obs_blade/shared/design/design.dart';

import '../../../../stores/views/dashboard.dart';
import '../../../../types/extensions/int.dart';

/// The "On Air" status cluster of the dashboard app bar: a LIVE and a REC
/// pill which morph (color / pulse / glyph) with the current broadcast state
/// and carry their elapsed timers next to the label.
///
/// Timers keep tabular figures and the store-driven 1s poll cadence - the
/// digit change just crossfades softly instead of hard swapping.
class OnAirStatusCluster extends StatelessWidget {
  const OnAirStatusCluster({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();
    final AppStatusColors statusColors =
        Theme.of(context).extension<AppStatusColors>()!;

    return Observer(builder: (context) {
      final bool recordingActive =
          dashboardStore.isRecording && !dashboardStore.isRecordingPaused;

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _OnAirPill(
            label: 'LIVE',
            active: dashboardStore.isLive,
            activeColor: statusColors.live,
            timerText:
                ((dashboardStore.latestStreamTimeDurationMS ?? 0) ~/ 1000)
                    .secondsToFormattedDurationString(),
          ),
          const SizedBox(width: AppSpacing.md),
          _OnAirPill(
            label: 'REC',
            active: dashboardStore.isRecording,
            paused: dashboardStore.isRecording &&
                dashboardStore.isRecordingPaused,
            activeColor:
                recordingActive ? statusColors.recording : statusColors.warning,
            timerText:
                ((dashboardStore.latestRecordTimeDurationMS ?? 0) ~/ 1000)
                    .secondsToFormattedDurationString(),
          ),
        ],
      );
    });
  }
}

class _OnAirPill extends StatelessWidget {
  final String label;

  /// Whether the underlying broadcast state is on (streaming / recording
  /// incl. paused - paused keeps the pill lit in [AppStatusColors.warning])
  final bool active;

  /// Recording-paused state - swaps the pulsing dot for a pause glyph
  final bool paused;

  /// Signal color the pill morphs to while [active]
  final Color activeColor;

  /// Elapsed time readout (tabular figures) shown inside the pill
  final String timerText;

  const _OnAirPill({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.timerText,
    this.paused = false,
  });

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color mutedColor =
        textTheme.bodySmall?.color ?? Colors.grey[500]!;

    return AnimatedContainer(
      duration: AppMotion.medium,
      curve: AppMotion.standard,
      height: 28.0,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: AppRadius.pill,
        color: this.active
            ? this.activeColor.withValues(alpha: 0.14)
            : Colors.transparent,
        border: Border.all(
          color: this.active
              ? this.activeColor.withValues(alpha: 0.45)
              : Theme.of(context).dividerColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: AppMotion.fast,
            child: this.paused
                ? Icon(
                    key: const ValueKey('paused'),
                    CupertinoIcons.pause_fill,
                    size: 10.0,
                    color: this.activeColor,
                  )
                : this.active
                    ? StatusDot(
                        key: const ValueKey('active'),
                        size: 8.0,
                        color: this.activeColor,
                      )
                    : Container(
                        key: const ValueKey('inactive'),
                        height: 8.0,
                        width: 8.0,
                        decoration: BoxDecoration(
                          color: mutedColor,
                          shape: BoxShape.circle,
                        ),
                      ),
          ),
          const SizedBox(width: AppSpacing.sm),
          AnimatedDefaultTextStyle(
            duration: AppMotion.medium,
            curve: AppMotion.standard,
            style: textTheme.labelSmall!.copyWith(
              color: this.active ? this.activeColor : mutedColor,
            ),
            child: Text(this.label),
          ),
          const SizedBox(width: AppSpacing.sm),
          AnimatedDefaultTextStyle(
            duration: AppMotion.medium,
            curve: AppMotion.standard,
            style: textTheme.labelMedium!.copyWith(
              color: this.active
                  ? textTheme.bodyMedium?.color
                  : mutedColor,
              fontFeatures: kTabularFigures,
            ),
            child: AnimatedSwitcher(
              duration: AppMotion.fast,
              child: Text(
                this.timerText,
                key: ValueKey(this.timerText),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
