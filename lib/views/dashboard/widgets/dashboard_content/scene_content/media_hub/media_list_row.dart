import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/general/base/icon_button.dart';
import '../../../../../../stores/views/dashboard.dart';
import '../../../../../../types/classes/media/media_status.dart';
import 'media_clock.dart';

/// Hub list row: name, position / state, and restart + play/pause + stop.
/// Tapping the row opens the full transport sheet (seek, VLC skip).
class MediaListRow extends StatelessWidget {
  final String inputName;
  final VoidCallback onOpenTransport;

  const MediaListRow({
    super.key,
    required this.inputName,
    required this.onOpenTransport,
  });

  @override
  Widget build(BuildContext context) {
    final DashboardStore dashboardStore = GetIt.instance<DashboardStore>();
    final ThemeData theme = Theme.of(context);
    final AppTextColors textColors = theme.extension<AppTextColors>()!;
    final Color accent = theme.buttonTheme.colorScheme!.secondary;

    return Observer(
      builder: (context) {
        final MediaStatus? status = dashboardStore.mediaStatus[this.inputName];
        final bool playing = status?.playing ?? false;
        final bool inProgram =
            dashboardStore.mediaInProgram[this.inputName] ?? true;

        /// OBS says playing but the source isn't live: it holds its
        /// position (and resumes once live, unless it restarts)
        final bool onHold = playing && !inProgram;

        /// Not live: everything but the reason fades well past the grey
        /// of a plain stopped row
        final double dim = inProgram ? 1.0 : 0.4;
        final Color notLive = theme.extension<AppStatusColors>()!.warning;

        return Pressable(
          onTap: this.onOpenTransport,
          child: ListTile(
            dense: true,
            leading: Opacity(
              opacity: dim,
              child: Icon(
                onHold
                    ? CupertinoIcons.pause_fill
                    : playing
                    ? CupertinoIcons.play_fill
                    : CupertinoIcons.music_note_2,
                color: playing && inProgram ? accent : null,
              ),
            ),
            title: Opacity(
              opacity: dim,
              child: Text(
                this.inputName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            subtitle: MediaClock(
              /// Outside the live scene OBS reports "playing" with a frozen
              /// cursor - don't run the clock on it
              running: playing && inProgram,
              builder: (context, now) => Row(
                children: [
                  Flexible(
                    child: Opacity(
                      opacity: dim,
                      child: Text(
                        mediaStatusLine(status, now, live: inProgram),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall!.copyWith(
                          fontFeatures: kTabularFigures,
                          color: textColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  if (!inProgram) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      CupertinoIcons.speaker_slash_fill,
                      size: 12.0,
                      color: notLive,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Not in the live scene',
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: notLive,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing: StaleGuard(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// OBS only plays media in the live scene - starting it
                  /// elsewhere is accepted but nothing plays, so those
                  /// buttons lock (the row still opens the transport sheet,
                  /// which says why)
                  Opacity(
                    opacity: dim,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TransportButton(
                          icon: CupertinoIcons.arrow_counterclockwise,
                          label: 'Restart ${this.inputName}',
                          onTap: inProgram
                              ? () => dashboardStore.triggerMediaAction(
                                  this.inputName,
                                  kMediaActionRestart,
                                )
                              : null,
                        ),
                        _TransportButton(
                          icon: playing
                              ? CupertinoIcons.pause_fill
                              : CupertinoIcons.play_fill,
                          label: playing
                              ? 'Pause ${this.inputName}'
                              : 'Play ${this.inputName}',
                          onTap: inProgram || playing
                              ? () => dashboardStore.triggerMediaAction(
                                  this.inputName,
                                  playing
                                      ? kMediaActionPause
                                      : kMediaActionPlay,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                  _TransportButton(
                    icon: CupertinoIcons.stop_fill,
                    label: 'Stop ${this.inputName}',
                    onTap: (status?.active ?? false)
                        ? () => dashboardStore.triggerMediaAction(
                            this.inputName,
                            kMediaActionStop,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// `0:12 / 0:45`, or the state when nothing is loaded
///
/// [live] false: OBS reports "playing" for a source outside the live scene
/// but its cursor doesn't move - show the held position, not a running one.
String mediaStatusLine(MediaStatus? status, DateTime now, {bool live = true}) {
  if (status == null) return '—';
  if (!live && status.playing) {
    final int? cursor = status.cursor;
    return cursor == null ? 'On hold' : 'On hold at ${formatMediaTime(cursor)}';
  }
  final int? cursor = status.cursorAt(now);
  final int? duration = status.duration;
  if (status.active && cursor != null && duration != null) {
    return '${formatMediaTime(cursor)} / ${formatMediaTime(duration)}';
  }
  return switch (status.state) {
    'OBS_MEDIA_STATE_ENDED' => 'Ended',
    'OBS_MEDIA_STATE_STOPPED' => 'Stopped',
    'OBS_MEDIA_STATE_OPENING' => 'Opening…',
    'OBS_MEDIA_STATE_BUFFERING' => 'Buffering…',
    'OBS_MEDIA_STATE_ERROR' => 'Error',
    _ => 'Ready',
  };
}

class _TransportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _TransportButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: this.onTap != null,
    label: this.label,
    excludeSemantics: true,
    child: Pressable(
      haptic: true,
      onTap: this.onTap,
      child: SizedBox(
        width: kBaseIconButtonMinHitArea,
        height: kBaseIconButtonMinHitArea,
        child: Center(
          child: Icon(
            this.icon,
            size: 20.0,
            color: this.onTap == null ? Theme.of(context).disabledColor : null,
          ),
        ),
      ),
    ),
  );
}
