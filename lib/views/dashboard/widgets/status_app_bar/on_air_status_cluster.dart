import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/animator/status_dot.dart';
import 'package:obs_blade/shared/design/design.dart';

import '../../../../shared/general/hive_builder.dart';
import '../../../../stores/views/canvas_view.dart';
import '../../../../stores/views/dashboard.dart';
import '../../../../types/classes/api/aitum_vertical.dart';
import '../../../../types/classes/api/obs_canvas.dart';
import '../../../../types/enums/hive_keys.dart';
import '../../../../types/enums/settings_keys.dart';
import '../../../../types/extensions/int.dart';

/// The "On Air" status cluster of the dashboard app bar: a LIVE and a REC
/// pill which morph (color / pulse / glyph) with the current broadcast state
/// and carry their elapsed timers next to the label.
///
/// Timers keep tabular figures and the store-driven 1s poll cadence - the
/// digit change just crossfades softly instead of hard swapping.
///
/// While another canvas is on air - sent along with the main stream (Twitch
/// Dual Format) or through Aitum Vertical's own outputs - a compact
/// [ExtraCanvasOnAirPill] joins them, the only sign of it while the main
/// canvas is shown. The row scales down instead of overflowing on narrow
/// phones.
class OnAirStatusCluster extends StatelessWidget {
  const OnAirStatusCluster({super.key});

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();
    final AppStatusColors statusColors = Theme.of(
      context,
    ).extension<AppStatusColors>()!;

    return Observer(
      builder: (context) {
        final bool recordingActive =
            dashboardStore.isRecording && !dashboardStore.isRecordingPaused;

        /// While the socket is reconnecting the broadcast state is unknown -
        /// the pills must not assert "you're live/recording" over a dead
        /// connection, so they drop to the neutral unknown state (gray dot +
        /// label, no breathe, timer hidden - token-delta §5)
        final bool reconnecting = dashboardStore.reconnecting;

        final CanvasViewStore? canvasStore = canvasViewStoreOrNull();

        /// Unknown while reconnecting - never assert the vertical output
        /// over a dead connection either
        final ExtraCanvasOnAir? extraOnAir = reconnecting
            ? null
            : canvasStore?.extraCanvasOnAir;

        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OnAirPill(
                label: 'LIVE',
                active: dashboardStore.isLive,
                unknown: reconnecting,
                activeColor: statusColors.live,
                timerText:
                    ((dashboardStore.latestStreamTimeDurationMS ?? 0) ~/ 1000)
                        .secondsToFormattedDurationString(),
              ),
              const SizedBox(width: AppSpacing.md),
              OnAirPill(
                label: 'REC',
                active: dashboardStore.isRecording,
                unknown: reconnecting,
                paused:
                    dashboardStore.isRecording &&
                    dashboardStore.isRecordingPaused,
                activeColor: recordingActive
                    ? statusColors.recording
                    : statusColors.warning,

                /// Red status text on a same-hue tint resolves the brightened
                /// [AppStatusColors.recordingText] derivative (§2.3)
                activeTextColor: recordingActive
                    ? statusColors.recordingText
                    : null,
                timerText:
                    ((dashboardStore.latestRecordTimeDurationMS ?? 0) ~/ 1000)
                        .secondsToFormattedDurationString(),
              ),
              AnimatedSwitcher(
                duration: AppMotion.medium,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    axis: Axis.horizontal,
                    sizeFactor: animation,
                    child: child,
                  ),
                ),
                child: extraOnAir != null
                    ? Padding(
                        key: const ValueKey('vertical'),
                        padding: const EdgeInsets.only(left: AppSpacing.md),
                        child: ExtraCanvasOnAirPill(
                          canvasStore: canvasStore!,
                          onAir: extraOnAir,
                        ),
                      )
                    : const SizedBox(key: ValueKey('no-vertical')),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Another canvas on air, in the app bar: a glyph for its shape (phone for
/// portrait, stacked frames otherwise) + LIVE / REC, no timers (neither the
/// main stream's extra canvas nor Aitum's outputs have their own). Tapping
/// it shows that canvas, outside streaming mode (always the main canvas)
/// and only with the canvas picker on.
class ExtraCanvasOnAirPill extends StatelessWidget {
  final CanvasViewStore canvasStore;
  final ExtraCanvasOnAir onAir;

  const ExtraCanvasOnAirPill({
    super.key,
    required this.canvasStore,
    required this.onAir,
  });

  @override
  Widget build(BuildContext context) {
    final AppStatusColors statusColors = Theme.of(
      context,
    ).extension<AppStatusColors>()!;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [
        SettingsKeys.StreamingMode,
        SettingsKeys.ExposeCanvasSwitcher,
      ],

      /// No Observer of its own - [onAir] comes from the cluster's, which
      /// rebuilds this pill whenever the state changes
      builder: (context, settingsBox, child) {
        final status = this.onAir;
        final bool recordingActive =
            status.recording && !status.recordingPaused;

        /// Streaming leads (green), else the recording's red / paused
        /// amber - same signal grammar as the main pills
        final Color color = status.streaming
            ? statusColors.live
            : recordingActive
            ? statusColors.recording
            : statusColors.warning;
        final Color textColor = !status.streaming && recordingActive
            ? statusColors.recordingText
            : color;

        /// Each part in its own signal color - REC stays red / amber
        /// next to a green LIVE
        final Color recColor = recordingActive
            ? statusColors.recordingText
            : statusColors.warning;

        final bool canJump =
            !(settingsBox.get(
                  SettingsKeys.StreamingMode.name,
                  defaultValue: false,
                )
                as bool) &&
            (settingsBox.get(
                  SettingsKeys.ExposeCanvasSwitcher.name,
                  defaultValue: true,
                )
                as bool);
        final ObsCanvas canvas = status.canvas;

        final Widget pill = Container(
          height: 28.0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.pill,
            color: color.withValues(alpha: 0.14),
            border: Border.all(color: color.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                canvas.isPortrait
                    ? CupertinoIcons.device_phone_portrait
                    : CupertinoIcons.rectangle_on_rectangle,
                size: 13.0,
                color: textColor,
              ),
              const SizedBox(width: AppSpacing.xs),
              status.recording && status.recordingPaused && !status.streaming
                  ? Icon(CupertinoIcons.pause_fill, size: 10.0, color: color)
                  : StatusDot(size: 8.0, color: color),
              const SizedBox(width: AppSpacing.sm),
              Text.rich(
                TextSpan(
                  children: [
                    if (status.streaming)
                      TextSpan(
                        text: 'LIVE',
                        style: TextStyle(color: statusColors.live),
                      ),
                    if (status.streaming && status.recording)
                      TextSpan(
                        text: ' · ',
                        style: TextStyle(color: textTheme.bodySmall?.color),
                      ),
                    if (status.recording)
                      TextSpan(
                        text: 'REC',
                        style: TextStyle(color: recColor),
                      ),
                  ],
                ),
                style: textTheme.labelSmall,
              ),
            ],
          ),
        );

        final String states = [
          if (status.streaming)
            status.viaMainStream ? 'live with the main stream' : 'live',
          if (status.recording)
            status.recordingPaused ? 'recording paused' : 'recording',
        ].join(', ');

        return Semantics(
          button: canJump,
          label: '${canvas.name}: $states',
          hint: canJump ? 'Shows the ${canvas.name} canvas' : null,
          excludeSemantics: true,
          child: canJump
              ? Pressable(
                  haptic: true,
                  onTap: () => this.canvasStore.viewCanvas(canvas.uuid),
                  child: pill,
                )
              : pill,
        );
      },
    );
  }
}

class OnAirPill extends StatelessWidget {
  final String label;

  /// Whether the underlying broadcast state is on (streaming / recording
  /// incl. paused - paused keeps the pill lit in [AppStatusColors.warning])
  final bool active;

  /// Recording-paused state - swaps the pulsing dot for a pause glyph
  final bool paused;

  /// Signal color the pill morphs to while [active]
  final Color activeColor;

  /// Optional brightened derivative for the label text while [active]
  /// (e.g. [AppStatusColors.recordingText] on the REC pill) - falls back
  /// to [activeColor]
  final Color? activeTextColor;

  /// Connection-state unknown (reconnecting): renders the neutral inactive
  /// treatment and hides the timer regardless of [active] (token-delta §5)
  final bool unknown;

  /// Elapsed time readout (tabular figures) shown inside the pill
  final String timerText;

  const OnAirPill({
    super.key,
    required this.label,
    required this.active,
    required this.activeColor,
    required this.timerText,
    this.activeTextColor,
    this.paused = false,
    this.unknown = false,
  });

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color mutedColor = textTheme.bodySmall?.color ?? Colors.grey[500]!;

    /// Unknown (reconnecting) forces the neutral treatment - an armed pill
    /// must not assert broadcast state over a dead connection
    final bool active = this.active && !this.unknown;

    return AnimatedContainer(
      duration: AppMotion.medium,
      curve: AppMotion.standard,
      height: 28.0,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: AppRadius.pill,
        color: active
            ? this.activeColor.withValues(alpha: 0.14)
            : Colors.transparent,
        border: Border.all(
          color: active
              ? this.activeColor.withValues(alpha: 0.45)
              : Theme.of(context).dividerColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: AppMotion.fast,
            child: this.paused && active
                ? Icon(
                    key: const ValueKey('paused'),
                    CupertinoIcons.pause_fill,
                    size: 10.0,
                    color: this.activeColor,
                  )
                : active
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
              color: active
                  ? (this.activeTextColor ?? this.activeColor)
                  : mutedColor,
            ),
            child: Text(this.label),
          ),
          if (!this.unknown) ...[
            const SizedBox(width: AppSpacing.sm),
            AnimatedDefaultTextStyle(
              duration: AppMotion.medium,
              curve: AppMotion.standard,
              style: textTheme.labelMedium!.copyWith(
                color: active ? textTheme.bodyMedium?.color : mutedColor,
                fontFeatures: kTabularFigures,
              ),
              child: AnimatedSwitcher(
                duration: AppMotion.fast,
                child: Text(this.timerText, key: ValueKey(this.timerText)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
