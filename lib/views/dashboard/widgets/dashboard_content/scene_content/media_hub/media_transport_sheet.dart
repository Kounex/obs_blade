import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/general/base/divider.dart';
import '../../../../../../shared/general/base/icon_button.dart';
import '../../../../../../stores/views/dashboard.dart';
import '../../../../../../types/classes/api/input.dart';
import '../../../../../../types/classes/media/media_status.dart';
import 'media_clock.dart';
import 'media_list_row.dart';

/// Full transport for one media input: seek, play/pause, restart, stop,
/// and previous / next for VLC playlists. Opened from a pad (long press)
/// or a hub list row (tap).
class MediaTransportSheet extends StatefulWidget {
  final String inputName;

  const MediaTransportSheet({super.key, required this.inputName});

  @override
  State<MediaTransportSheet> createState() => _MediaTransportSheetState();
}

class _MediaTransportSheetState extends State<MediaTransportSheet> {
  /// Local drag position so the thumb follows the finger; committed on
  /// release
  double? _draggingCursor;

  @override
  void initState() {
    super.initState();
    GetIt.instance<DashboardStore>().requestMediaStatus(this.widget.inputName);
  }

  @override
  Widget build(BuildContext context) {
    final DashboardStore dashboardStore = GetIt.instance<DashboardStore>();
    final ThemeData theme = Theme.of(context);
    final AppTextColors textColors = theme.extension<AppTextColors>()!;

    return Observer(
      builder: (context) {
        final MediaStatus? status =
            dashboardStore.mediaStatus[this.widget.inputName];
        final bool playing = status?.playing ?? false;
        final bool inProgram =
            dashboardStore.mediaInProgram[this.widget.inputName] ?? true;
        Input? input;
        for (final candidate in dashboardStore.mediaInputs) {
          if (candidate.inputName == this.widget.inputName) input = candidate;
        }
        final bool vlc = isVlcInputKind(input?.inputKind);
        final int? duration = status?.duration;

        void action(String mediaAction) => dashboardStore.triggerMediaAction(
          this.widget.inputName,
          mediaAction,
        );

        return SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 24.0) +
              EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xl,
              ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(this.widget.inputName, style: theme.textTheme.headlineSmall),
              Text(
                vlc ? 'VLC Video Source' : 'Media Source',
                style: theme.textTheme.bodySmall,
              ),
              if (!inProgram) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.speaker_slash_fill,
                      size: 16.0,
                      color: textColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Not in program - OBS plays it, but the stream won\'t hear it until the source is in the live scene.',
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: textColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              const BaseDivider(),
              const SizedBox(height: AppSpacing.md),
              MediaClock(
                running: playing && _draggingCursor == null,
                builder: (context, now) {
                  final int cursor =
                      _draggingCursor?.round() ?? status?.cursorAt(now) ?? 0;
                  final bool seekable =
                      duration != null &&
                      duration > 0 &&
                      (status?.active ?? false);
                  return Column(
                    children: [
                      StaleGuard(
                        child: Slider(
                          min: 0.0,
                          max: seekable ? duration.toDouble() : 1.0,
                          value: seekable
                              ? cursor.clamp(0, duration).toDouble()
                              : 0.0,
                          semanticFormatterCallback: (value) =>
                              formatMediaTime(value.round()),
                          onChanged: seekable
                              ? (value) =>
                                    setState(() => _draggingCursor = value)
                              : null,
                          onChangeEnd: (value) async {
                            await dashboardStore.setMediaCursor(
                              this.widget.inputName,
                              value.round(),
                            );
                            if (this.mounted) {
                              setState(() => _draggingCursor = null);
                            }
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: Row(
                          children: [
                            Text(
                              seekable
                                  ? formatMediaTime(cursor)
                                  : mediaStatusLine(status, now),
                              style: theme.textTheme.bodySmall!.copyWith(
                                fontFeatures: kTabularFigures,
                                color: textColors.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            if (duration != null && duration > 0)
                              Text(
                                formatMediaTime(duration),
                                style: theme.textTheme.bodySmall!.copyWith(
                                  fontFeatures: kTabularFigures,
                                  color: textColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              StaleGuard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (vlc)
                      _SheetButton(
                        icon: CupertinoIcons.backward_end_fill,
                        label: 'Previous',
                        onTap: () => action(kMediaActionPrevious),
                      ),
                    _SheetButton(
                      icon: CupertinoIcons.arrow_counterclockwise,
                      label: 'Restart',
                      onTap: () => action(kMediaActionRestart),
                    ),
                    _SheetButton(
                      icon: playing
                          ? CupertinoIcons.pause_fill
                          : CupertinoIcons.play_fill,
                      label: playing ? 'Pause' : 'Play',
                      primary: true,
                      onTap: () => action(
                        playing ? kMediaActionPause : kMediaActionPlay,
                      ),
                    ),
                    _SheetButton(
                      icon: CupertinoIcons.stop_fill,
                      label: 'Stop',
                      onTap: (status?.active ?? false)
                          ? () => action(kMediaActionStop)
                          : null,
                    ),
                    if (vlc)
                      _SheetButton(
                        icon: CupertinoIcons.forward_end_fill,
                        label: 'Next',
                        onTap: () => action(kMediaActionNext),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SheetButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;

  const _SheetButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = theme.buttonTheme.colorScheme!.secondary;
    final double size = this.primary ? 64.0 : kBaseIconButtonMinHitArea + 8.0;

    return Semantics(
      button: true,
      enabled: this.onTap != null,
      label: this.label,
      excludeSemantics: true,
      child: Pressable(
        haptic: true,
        onTap: this.onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: this.primary
                ? accent
                : theme.colorScheme.onSurface.withValues(alpha: 0.06),
          ),
          child: Icon(
            this.icon,
            size: this.primary ? 28.0 : 22.0,
            color: this.onTap == null
                ? theme.disabledColor
                : this.primary
                ? theme.colorScheme.onSecondary
                : null,
          ),
        ),
      ),
    );
  }
}
