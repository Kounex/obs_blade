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
    GetIt.instance<DashboardStore>()
      ..requestMediaStatus(this.widget.inputName)
      ..requestMediaSettings(this.widget.inputName);
  }

  @override
  Widget build(BuildContext context) {
    final DashboardStore dashboardStore = GetIt.instance<DashboardStore>();
    final ThemeData theme = Theme.of(context);
    final AppTextColors textColors = theme.extension<AppTextColors>()!;

    return Observer(
      builder: (context) {
        final MediaPlayback playback = dashboardStore.mediaPlayback(
          this.widget.inputName,
        );
        final bool playing = playback.playing;
        final bool inProgram = playback.live;
        Input? input;
        for (final candidate in dashboardStore.mediaInputs) {
          if (candidate.inputName == this.widget.inputName) input = candidate;
        }
        final bool vlc = isVlcInputKind(input?.inputKind);
        final int? duration = playback.status?.duration;

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
                      color: theme.extension<AppStatusColors>()!.warning,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        notLiveExplanation(playback.behavior),
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: theme.extension<AppStatusColors>()!.warning,
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
                running: playback.running && _draggingCursor == null,
                builder: (context, now) {
                  final int cursor =
                      _draggingCursor?.round() ?? playback.cursorAt(now) ?? 0;
                  final bool seekable = playback.canSeek;
                  return Column(
                    children: [
                      StaleGuard(
                        child: Slider(
                          min: 0.0,
                          max: seekable ? duration!.toDouble() : 1.0,
                          value: seekable
                              ? cursor.clamp(0, duration!).toDouble()
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
                                  : playback.line(now),
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
                        onTap: playback.canStart
                            ? () => action(kMediaActionPrevious)
                            : null,
                      ),
                    _SheetButton(
                      icon: CupertinoIcons.arrow_counterclockwise,
                      label: 'Restart',
                      onTap: playback.canStart
                          ? () => action(kMediaActionRestart)
                          : null,
                    ),
                    _SheetButton(
                      icon: playing
                          ? CupertinoIcons.pause_fill
                          : CupertinoIcons.play_fill,
                      label: playing ? 'Pause' : 'Play',
                      primary: true,

                      /// Starting is locked outside the live scene; pausing
                      /// stays possible, resuming where it plays on unheard
                      onTap: playback.canPlayPause
                          ? () => action(
                              playing ? kMediaActionPause : kMediaActionPlay,
                            )
                          : null,
                    ),
                    _SheetButton(
                      icon: CupertinoIcons.stop_fill,
                      label: 'Stop',
                      onTap: playback.canStop
                          ? () => action(kMediaActionStop)
                          : null,
                    ),
                    if (vlc)
                      _SheetButton(
                        icon: CupertinoIcons.forward_end_fill,
                        label: 'Next',
                        onTap: playback.canStart
                            ? () => action(kMediaActionNext)
                            : null,
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

/// Why the controls are locked outside the live scene, and what OBS does
/// with the source meanwhile
String notLiveExplanation(MediaLiveBehavior? behavior) {
  const String fix =
      'Switch to its scene first, or put your clips in a scene you nest into your main scenes.';
  return switch (behavior) {
    MediaLiveBehavior.keepsPlaying =>
      'Not in the live scene. OBS keeps playing it unheard and carries on from there once its scene is live - starting from the top and seeking only work in the live scene. $fix',
    MediaLiveBehavior.restarts =>
      'Not in the live scene. OBS plays it from the start whenever its scene goes live ("Restart playback when source becomes active" in its OBS properties). $fix',
    MediaLiveBehavior.holds =>
      'Not in the live scene. OBS holds it and resumes once its scene is live. $fix',
    null =>
      'Not in the live scene. OBS only starts media in the live scene. $fix',
  };
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
