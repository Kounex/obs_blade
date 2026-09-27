import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../shared/design/design.dart';
import '../../../../../../stores/views/dashboard.dart';
import '../../../../../../types/classes/media/media_status.dart';
import 'media_clock.dart';

/// Soundboard pad: a tap (re)starts the clip from the top - also while it
/// plays, the way a soundboard behaves. A long press opens the full
/// transport ([onOpenTransport]). Playing pads carry an accent ring and a
/// progress bar; pads that aren't in program are dimmed with a
/// speaker-slash marker - OBS only plays media in the live scene.
class MediaPad extends StatelessWidget {
  final String inputName;
  final VoidCallback onOpenTransport;

  const MediaPad({
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
        final bool paused = status?.paused ?? false;

        /// Unknown (not read yet) counts as heard - no false alarm
        final bool inProgram =
            dashboardStore.mediaInProgram[this.inputName] ?? true;

        final String stateText = playing
            ? 'playing'
            : paused
            ? 'paused'
            : 'stopped';

        return StaleGuard(
          child: Semantics(
            button: true,
            label: [
              this.inputName,
              stateText,
              if (!inProgram) 'not in the live scene',
            ].join(', '),
            hint: inProgram
                ? 'Plays from the start. Long press for more controls'
                : 'Opens its controls - it only plays in the live scene',
            onLongPress: this.onOpenTransport,
            excludeSemantics: true,
            child: GestureDetector(
              onLongPress: () {
                HapticFeedback.mediumImpact();
                this.onOpenTransport();
              },
              child: Pressable(
                haptic: true,

                /// Outside the live scene OBS accepts the start but plays
                /// nothing - open the controls instead, which say why
                onTap: inProgram
                    ? () => dashboardStore.triggerMediaAction(
                        this.inputName,
                        kMediaActionRestart,
                      )
                    : this.onOpenTransport,
                child: AnimatedContainer(
                  duration: AppMotion.fast,
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      playing
                          ? accent.withValues(alpha: 0.14)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                      theme.cardColor,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: playing
                          ? accent
                          : theme.dividerColor.withValues(alpha: 0.4),
                      width: playing ? 2.0 : 1.0,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md - 1.0),
                    child: Stack(
                      children: [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.lg + AppSpacing.xs,
                              AppSpacing.md,
                              AppSpacing.lg + AppSpacing.xs,
                            ),
                            child: AutoSizeText(
                              this.inputName,
                              maxLines: 3,
                              minFontSize: 10.0,
                              wrapWords: false,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleSmall!.copyWith(
                                fontWeight: FontWeight.w600,
                                color: inProgram
                                    ? null
                                    : textColors.textTertiary,
                              ),
                            ),
                          ),
                        ),
                        if (playing || paused)
                          Positioned(
                            left: AppSpacing.sm,
                            top: AppSpacing.sm,
                            child: Icon(
                              playing
                                  ? CupertinoIcons.play_fill
                                  : CupertinoIcons.pause_fill,
                              size: 14.0,
                              color: playing
                                  ? accent
                                  : textColors.textSecondary,
                            ),
                          ),
                        if (!inProgram)
                          Positioned(
                            right: AppSpacing.sm,
                            top: AppSpacing.sm,
                            child: Icon(
                              CupertinoIcons.speaker_slash_fill,
                              size: 14.0,
                              color: textColors.textTertiary,
                            ),
                          ),
                        if (status != null && (playing || paused))
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: MediaClock(
                              running: playing && inProgram,
                              builder: (context, now) {
                                final double? progress = status.progressAt(now);
                                final int? cursor = status.cursorAt(now);
                                final int? duration = status.duration;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (cursor != null && duration != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: AppSpacing.sm,
                                          bottom: AppSpacing.xs,
                                        ),
                                        child: Text(
                                          '-${formatMediaTime(duration - cursor)}',
                                          style: theme.textTheme.labelSmall!
                                              .copyWith(
                                                fontFeatures: kTabularFigures,
                                                color: textColors.textSecondary,
                                              ),
                                        ),
                                      ),
                                    if (progress != null)
                                      LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 3.0,
                                        color: accent,
                                        backgroundColor: accent.withValues(
                                          alpha: 0.18,
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
