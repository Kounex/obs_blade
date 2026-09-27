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
        final MediaPlayback playback = dashboardStore.mediaPlayback(
          this.inputName,
        );
        final bool live = playback.live;

        /// Not live: everything but the reason fades well past the grey
        /// of a plain stopped row
        final double dim = live ? 1.0 : 0.4;
        final Color notLive = theme.extension<AppStatusColors>()!.warning;

        return Pressable(
          onTap: this.onOpenTransport,
          child: ListTile(
            dense: true,
            leading: Opacity(
              opacity: dim,
              child: Icon(
                playback.running
                    ? CupertinoIcons.play_fill
                    : playback.showsPosition
                    ? CupertinoIcons.pause_fill
                    : CupertinoIcons.music_note_2,
                color: playback.running && live ? accent : null,
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
              running: playback.running,
              builder: (context, now) => Row(
                children: [
                  Flexible(
                    child: Opacity(
                      opacity: dim,
                      child: Text(
                        playback.line(now),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall!.copyWith(
                          fontFeatures: kTabularFigures,
                          color: textColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  if (!live) ...[
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

            /// OBS only starts media in the live scene - those buttons lock
            /// elsewhere (the row still opens the transport sheet, which
            /// says why); pausing / stopping what plays unheard stays
            trailing: StaleGuard(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TransportButton(
                    icon: CupertinoIcons.arrow_counterclockwise,
                    label: 'Restart ${this.inputName}',
                    onTap: playback.canStart
                        ? () => dashboardStore.triggerMediaAction(
                            this.inputName,
                            kMediaActionRestart,
                          )
                        : null,
                  ),
                  _TransportButton(
                    icon: playback.playing
                        ? CupertinoIcons.pause_fill
                        : CupertinoIcons.play_fill,
                    label: playback.playing
                        ? 'Pause ${this.inputName}'
                        : 'Play ${this.inputName}',
                    onTap: playback.canPlayPause
                        ? () => dashboardStore.triggerMediaAction(
                            this.inputName,
                            playback.playing
                                ? kMediaActionPause
                                : kMediaActionPlay,
                          )
                        : null,
                  ),
                  _TransportButton(
                    icon: CupertinoIcons.stop_fill,
                    label: 'Stop ${this.inputName}',
                    onTap: playback.canStop
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
