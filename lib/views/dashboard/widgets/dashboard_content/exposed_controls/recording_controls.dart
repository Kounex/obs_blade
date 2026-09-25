import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../shared/general/base/button.dart';
import '../../../../../shared/general/hive_builder.dart';
import '../../../../../shared/overlay/base_result.dart';
import '../../../../../stores/views/dashboard.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/request_type.dart';
import '../../../../../types/enums/settings_keys.dart';
import '../../../../../utils/overlay_handler.dart';
import '../../../services/record_stream.dart';
import 'exposed_controls.dart';

class RecordingControls extends StatelessWidget {
  const RecordingControls({super.key});

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [
        SettingsKeys.DontShowRecordStartMessage,
        SettingsKeys.DontShowRecordStopMessage,
      ],
      builder: (context, settingsBox, child) => Observer(
        builder: (context) => Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: BaseButton(
                    onPressed: () => RecordStreamService.triggerRecordStartStop(
                      context,
                      dashboardStore.isRecording,
                      settingsBox.get(
                        SettingsKeys.DontShowRecordStartMessage.name,
                        defaultValue: false,
                      ),
                      settingsBox.get(
                        SettingsKeys.DontShowRecordStopMessage.name,
                        defaultValue: false,
                      ),
                    ),
                    icon: Icon(
                      dashboardStore.isRecording
                          ? CupertinoIcons.stop
                          : CupertinoIcons.recordingtape,
                    ),

                    /// Ghost button (token-delta §2.6): no green/red state fills
                    /// - red is reserved for recording/program state (rule 7),
                    /// which the REC pill carries
                    secondary: true,
                    text: dashboardStore.isRecording ? 'Stop' : 'Start',
                  ),
                ),
                const SizedBox(width: kExposedControlsSpace),
                Expanded(
                  child: BaseButton(
                    onPressed: dashboardStore.isRecording
                        ? () {
                            HapticFeedback.lightImpact();
                            dashboardStore.sendMutation(
                              RequestType.ToggleRecordPause,
                              label: 'Recording pause/resume',
                            );
                          }
                        : null,
                    icon: Icon(
                      dashboardStore.isRecordingPaused
                          ? CupertinoIcons.play
                          : CupertinoIcons.pause,
                    ),

                    /// Ghost button - the hardcoded green/orange state fills
                    /// encoded nothing per the color grammar (rules 7+8)
                    secondary: true,
                    text: dashboardStore.isRecordingPaused ? 'Resume' : 'Pause',
                  ),
                ),
              ],
            ),

            /// OBS 30.2+ only (gated on GetVersion's availableRequests, so
            /// older OBS never shows dead buttons). Chapters only land in
            /// Hybrid MP4 recordings - OBS rejects the request otherwise,
            /// which the command-failure toast surfaces.
            if (dashboardStore.supportsRequest(RequestType.SplitRecordFile) ||
                dashboardStore.supportsRequest(
                  RequestType.CreateRecordChapter,
                )) ...[
              const SizedBox(height: kExposedControlsSpace),
              Row(
                children: [
                  if (dashboardStore.supportsRequest(
                    RequestType.SplitRecordFile,
                  ))
                    Expanded(
                      child: BaseButton(
                        onPressed: dashboardStore.isRecording
                            ? () async {
                                HapticFeedback.lightImpact();
                                final ack = await dashboardStore.sendMutation(
                                  RequestType.SplitRecordFile,
                                  label: 'Split recording',
                                );
                                if (ack.success && context.mounted) {
                                  OverlayHandler.showStatusOverlay(
                                    context: context,
                                    replaceIfActive: true,
                                    content: const BaseResult(
                                      text: 'New file started',
                                    ),
                                  );
                                }
                              }
                            : null,
                        icon: const Icon(CupertinoIcons.scissors),
                        secondary: true,
                        text: 'Split File',
                      ),
                    ),
                  if (dashboardStore.supportsRequest(
                        RequestType.SplitRecordFile,
                      ) &&
                      dashboardStore.supportsRequest(
                        RequestType.CreateRecordChapter,
                      ))
                    const SizedBox(width: kExposedControlsSpace),
                  if (dashboardStore.supportsRequest(
                    RequestType.CreateRecordChapter,
                  ))
                    Expanded(
                      child: BaseButton(
                        onPressed: dashboardStore.isRecording
                            ? () async {
                                HapticFeedback.lightImpact();
                                final ack = await dashboardStore.sendMutation(
                                  RequestType.CreateRecordChapter,
                                  label: 'Chapter marker',
                                );
                                if (ack.success && context.mounted) {
                                  OverlayHandler.showStatusOverlay(
                                    context: context,
                                    replaceIfActive: true,
                                    content: const BaseResult(
                                      text: 'Chapter added',
                                    ),
                                  );
                                }
                              }
                            : null,
                        icon: const Icon(CupertinoIcons.bookmark_fill),
                        secondary: true,
                        text: 'Chapter',
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
