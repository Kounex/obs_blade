import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../../../shared/animator/status_dot.dart';
import '../../../../../shared/design/design.dart';
import '../../../../../shared/general/base/button.dart';
import '../../../../../shared/general/base/card.dart';
import '../../../../../shared/general/hive_builder.dart';
import '../../../../../shared/overlay/base_result.dart';
import '../../../../../stores/views/canvas_view.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';
import '../../../../../utils/modal_handler.dart';
import '../../../../../utils/overlay_handler.dart';
import '../dialogs/start_stop_recording_dialog.dart';
import '../dialogs/start_stop_streaming_dialog.dart';

/// Tells the user why a live action on the viewed canvas did nothing (no
/// Aitum Vertical, wrong canvas, OBS restart needed) - [prefix] says what
/// happened instead, if anything
void showCanvasLiveControlHint(
  BuildContext context,
  CanvasViewStore canvasStore, {
  String? prefix,
}) {
  final reason = canvasStore.liveControlBlockedReason;
  if (reason == null) return;
  OverlayHandler.showStatusOverlay(
    context: context,
    replaceIfActive: true,
    showDuration: const Duration(seconds: 4),
    content: BaseResult(
      icon: BaseResultIcon.Missing,
      text: prefix != null ? '$prefix\n\n$reason' : reason,
    ),
  );
}

/// Stream / record / backtrack of the viewed non-main canvas. These are
/// Aitum Vertical's own outputs (its vendor requests) - core OBS has none
/// for other canvases. Without live control the rows stay visible but
/// muted, and a tap explains what's missing instead of doing nothing.
class CanvasOutputControls extends StatelessWidget {
  const CanvasOutputControls({super.key});

  @override
  Widget build(BuildContext context) {
    final CanvasViewStore? canvasStore = canvasViewStoreOrNull();
    if (canvasStore == null) return const SizedBox();

    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [
        SettingsKeys.DontShowStreamStartMessage,
        SettingsKeys.DontShowStreamStopMessage,
        SettingsKeys.DontShowRecordStartMessage,
        SettingsKeys.DontShowRecordStopMessage,
      ],
      builder: (context, settingsBox, child) => Observer(
        builder: (context) {
          if (!canvasStore.isViewingOtherCanvas) return const SizedBox();

          final AppStatusColors statusColors = Theme.of(
            context,
          ).extension<AppStatusColors>()!;
          final bool live = canvasStore.canControlViewedCanvas;
          final status = canvasStore.aitumStatus;
          final String canvasName = canvasStore.viewedCanvas?.name ?? '';

          bool dontShow(SettingsKeys key) =>
              settingsBox.get(key.name, defaultValue: false) as bool;

          /// Gated tap: explain instead of sending
          VoidCallback guarded(VoidCallback action) => () {
            if (!live) {
              HapticFeedback.lightImpact();
              showCanvasLiveControlHint(context, canvasStore);
              return;
            }
            action();
          };

          void streamTap() {
            HapticFeedback.mediumImpact();
            final bool isLive = status.streaming;
            void send() => canvasStore.setAitumStreaming(!isLive);
            if (dontShow(
              isLive
                  ? SettingsKeys.DontShowStreamStopMessage
                  : SettingsKeys.DontShowStreamStartMessage,
            )) {
              send();
            } else {
              ModalHandler.showBaseDialog(
                context: context,
                dialogWidget: StartStopStreamingDialog(
                  isLive: isLive,
                  canvasName: canvasName,
                  onStreamStartStop: send,
                ),
              );
            }
          }

          void recordTap() {
            HapticFeedback.mediumImpact();
            final bool isRecording = status.recording;
            void send() => canvasStore.setAitumRecording(!isRecording);
            if (dontShow(
              isRecording
                  ? SettingsKeys.DontShowRecordStopMessage
                  : SettingsKeys.DontShowRecordStartMessage,
            )) {
              send();
            } else {
              ModalHandler.showBaseDialog(
                context: context,
                dialogWidget: StartStopRecordingDialog(
                  isRecording: isRecording,
                  canvasName: canvasName,
                  onRecordStartStop: send,
                ),
              );
            }
          }

          return BaseCard(
            topPadding: AppSpacing.md,
            rightPadding: AppSpacing.md,
            bottomPadding: 0.0,
            leftPadding: AppSpacing.md,
            child: StaleGuard(
              child: AnimatedOpacity(
                duration: AppMotion.medium,
                opacity: live ? 1.0 : 0.55,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    /// Names the canvas - the main output's exposed
                    /// Stream / Recording controls can sit on the same screen
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Text(
                        '$canvasName outputs',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    if (!live)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.info_circle,
                              size: 14.0,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                'View only - live controls need Aitum '
                                'Vertical',
                                maxLines: 2,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    _OutputRow(
                      label: 'Stream',
                      active: live && status.streaming,
                      activeColor: statusColors.live,
                      actions: [
                        _OutputButton(
                          text: status.streaming && live ? 'Stop' : 'Start',
                          semanticsLabel: status.streaming && live
                              ? 'Stop $canvasName stream'
                              : 'Start $canvasName stream',
                          onPressed: guarded(streamTap),
                        ),
                      ],
                    ),
                    _OutputRow(
                      label: 'Recording',
                      active: live && status.recording,
                      activeColor: status.recordingPaused
                          ? statusColors.warning
                          : statusColors.recording,
                      paused: live && status.recordingPaused,
                      actions: [
                        /// Icon-only: three labelled buttons don't fit a
                        /// phone row next to the label
                        if (live && status.recording) ...[
                          _OutputButton(
                            icon: status.recordingPaused
                                ? CupertinoIcons.play_fill
                                : CupertinoIcons.pause_fill,
                            semanticsLabel: status.recordingPaused
                                ? 'Resume $canvasName recording'
                                : 'Pause $canvasName recording',
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              canvasStore.setAitumRecordingPaused(
                                !status.recordingPaused,
                              );
                            },
                          ),
                          _OutputButton(
                            icon: CupertinoIcons.bookmark_fill,
                            semanticsLabel:
                                'Add a chapter marker to the $canvasName '
                                'recording',
                            onPressed: () async {
                              HapticFeedback.lightImpact();
                              if (await canvasStore.addAitumChapter() &&
                                  context.mounted) {
                                OverlayHandler.showStatusOverlay(
                                  context: context,
                                  replaceIfActive: true,
                                  content: const BaseResult(
                                    text: 'Chapter added',
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                        _OutputButton(
                          text: status.recording && live ? 'Stop' : 'Start',
                          semanticsLabel: status.recording && live
                              ? 'Stop $canvasName recording'
                              : 'Start $canvasName recording',
                          onPressed: guarded(recordTap),
                        ),
                      ],
                    ),
                    _OutputRow(
                      label: 'Backtrack',
                      active: live && status.backtrack,
                      activeColor: statusColors.live,
                      actions: [
                        if (live && status.backtrack)
                          _OutputButton(
                            text: 'Save',
                            semanticsLabel: 'Save $canvasName backtrack',
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              canvasStore.saveAitumBacktrack();
                            },
                          ),
                        _OutputButton(
                          text: status.backtrack && live ? 'Stop' : 'Start',
                          semanticsLabel: status.backtrack && live
                              ? 'Stop $canvasName backtrack'
                              : 'Start $canvasName backtrack',
                          onPressed: guarded(() {
                            HapticFeedback.mediumImpact();
                            canvasStore.setAitumBacktrack(!status.backtrack);
                          }),
                        ),
                      ],
                    ),
                    _OutputRow(
                      label: 'Virtual camera',

                      /// Not "on air" - live green is reserved for that
                      active: live && status.virtualCamera,
                      activeColor: Theme.of(context).colorScheme.secondary,
                      actions: [
                        _OutputButton(
                          text: status.virtualCamera && live ? 'Stop' : 'Start',
                          semanticsLabel: status.virtualCamera && live
                              ? 'Stop $canvasName virtual camera'
                              : 'Start $canvasName virtual camera',
                          onPressed: guarded(() {
                            HapticFeedback.mediumImpact();
                            canvasStore.setAitumVirtualCamera(
                              !status.virtualCamera,
                            );
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// One output: label + state dot on the left, its buttons on the right
class _OutputRow extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final List<Widget> actions;

  /// Paused output (recording): a pause glyph instead of the pulsing dot
  final bool paused;

  const _OutputRow({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.actions,
    this.paused = false,
  });

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color mutedColor = textTheme.bodySmall?.color ?? Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 12.0,
            child: this.paused
                ? Icon(
                    CupertinoIcons.pause_fill,
                    size: 10.0,
                    color: this.activeColor,
                  )
                : this.active
                ? StatusDot(
                    size: 8.0,
                    horizontalSpacing: 0.0,
                    verticalSpacing: 0.0,
                    color: this.activeColor,
                  )
                : Container(
                    height: 8.0,
                    width: 8.0,
                    decoration: BoxDecoration(
                      color: mutedColor,
                      shape: BoxShape.circle,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              this.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium,
            ),
          ),
          for (final (index, action) in this.actions.indexed) ...[
            if (index > 0) const SizedBox(width: AppSpacing.sm),
            action,
          ],
        ],
      ),
    );
  }
}

class _OutputButton extends StatelessWidget {
  /// Label - or [icon] for a compact icon-only button
  final String? text;
  final IconData? icon;
  final String semanticsLabel;
  final VoidCallback onPressed;

  const _OutputButton({
    this.text,
    this.icon,
    required this.semanticsLabel,
    required this.onPressed,
  }) : assert(text != null || icon != null);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: this.semanticsLabel,
      excludeSemantics: true,
      child: BaseButton(
        secondary: true,
        shrinkWidth: true,
        padding: EdgeInsets.symmetric(
          horizontal: this.text != null ? AppSpacing.lg : AppSpacing.md,
        ),
        text: this.text,
        child: this.icon != null ? Icon(this.icon, size: 18.0) : null,
        onPressed: this.onPressed,
      ),
    );
  }
}
