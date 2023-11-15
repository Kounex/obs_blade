import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:obs_blade/utils/overlay_handler.dart';

import '../../../../models/connection.dart';
import '../../../../shared/dialogs/confirmation.dart';
import '../../../../shared/general/app_bar_actions.dart';
import '../../../../shared/general/hive_builder.dart';
import '../../../../shared/overlay/base_progress_indicator.dart';
import '../../../../stores/shared/network.dart';
import '../../../../stores/views/dashboard.dart';
import '../../../../types/enums/hive_keys.dart';
import '../../../../types/enums/request_batch_type.dart';
import '../../../../types/enums/request_type.dart';
import '../../../../types/enums/settings_keys.dart';
import '../../../../utils/modal_handler.dart';
import '../../../../utils/network_helper.dart';
import '../../services/record_stream.dart';
import '../dialogs/save_edit_connection.dart';

class GeneralActions extends StatelessWidget {
  const GeneralActions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    NetworkStore networkStore = GetIt.instance<NetworkStore>();
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    return HiveBuilder<Connection>(
      hiveKey: HiveKeys.SavedConnections,
      builder: (context, savedConnectionsBox, child) {
        bool newConnection =
            networkStore.activeSession?.connection.name == null;
        return HiveBuilder<dynamic>(
          hiveKey: HiveKeys.Settings,
          rebuildKeys: const [
            SettingsKeys.ExposeStreamingControls,
            SettingsKeys.ExposeRecordingControls,
            SettingsKeys.DontShowHidingScenesWarning,
            SettingsKeys.DontShowRecordStartMessage,
            SettingsKeys.DontShowRecordStopMessage,
            SettingsKeys.DontShowStreamStartMessage,
            SettingsKeys.DontShowStreamStopMessage,
          ],
          builder: (context, settingsBox, child) => Observer(
            builder: (_) => AppBarActions(
              actions: [
                if (!settingsBox.get(SettingsKeys.ExposeStreamingControls.name,
                    defaultValue: false))
                  AppBarActionEntry(
                    title:
                        '${dashboardStore.isLive ? 'Stop' : 'Start'} Streaming',
                    onAction: () => RecordStreamService.triggerStreamStartStop(
                      context,
                      dashboardStore.isLive,
                      settingsBox.get(
                          SettingsKeys.DontShowStreamStartMessage.name,
                          defaultValue: false),
                      settingsBox.get(
                          SettingsKeys.DontShowStreamStopMessage.name,
                          defaultValue: false),
                    ),
                  ),
                if (!settingsBox.get(SettingsKeys.ExposeRecordingControls.name,
                    defaultValue: false)) ...[
                  AppBarActionEntry(
                    title:
                        '${dashboardStore.isRecording ? 'Stop' : 'Start'} Recording',
                    onAction: () => RecordStreamService.triggerRecordStartStop(
                      context,
                      dashboardStore.isRecording,
                      settingsBox.get(
                          SettingsKeys.DontShowRecordStartMessage.name,
                          defaultValue: false),
                      settingsBox.get(
                          SettingsKeys.DontShowRecordStopMessage.name,
                          defaultValue: false),
                    ),
                  ),
                  AppBarActionEntry(
                    title:
                        '${dashboardStore.isRecordingPaused ? 'Resume' : 'Pause'} Recording',
                    onAction: dashboardStore.isRecording
                        ? () => NetworkHelper.makeRequest(
                              networkStore.activeSession!.socket,
                              RequestType.ToggleRecordPause,
                            )
                        : null,
                  ),
                ],
                if (!settingsBox.get(
                    SettingsKeys.ExposeReplayBufferControls.name,
                    defaultValue: false)) ...[
                  AppBarActionEntry(
                    title:
                        '${dashboardStore.isReplayBufferActive ? 'Stop' : 'Start'} Replay Buffer',
                    onAction: () {
                      if (dashboardStore.isReplayBufferActive) {
                        OverlayHandler.showStatusOverlay(
                          showDuration: const Duration(seconds: 10),
                          context: context,
                          content: BaseProgressIndicator(
                            text: 'Stopping Replay Buffer...',
                          ),
                        );
                      }
                      NetworkHelper.makeRequest(
                        networkStore.activeSession!.socket,
                        RequestType.ToggleReplayBuffer,
                      );
                    },
                  ),
                  AppBarActionEntry(
                    title: 'Save Replay Buffer',
                    onAction: dashboardStore.isReplayBufferActive
                        ? () => NetworkHelper.makeRequest(
                              networkStore.activeSession!.socket,
                              RequestType.SaveReplayBuffer,
                            )
                        : null,
                  ),
                ],
                AppBarActionEntry(
                  title:
                      '${dashboardStore.isVirtualCamActive ? 'Stop' : 'Start'} Virtual Camera',
                  onAction: () {
                    NetworkHelper.makeRequest(
                      networkStore.activeSession!.socket,
                      RequestType.ToggleVirtualCam,
                    );
                  },
                ),
                AppBarActionEntry(
                  title: 'Take OBS Screenshot',
                  onAction: () {
                    /// Intentionally having a different file format used for
                    /// the [imageFormat] field for the request and the one
                    /// used as the extension for the file. If we can, we want
                    /// to save screenshots as pngs as OBS is doing it, but
                    /// when doing so here, transparency is used correctly
                    /// which OBS does not do... so I'm rather doing it like
                    /// OBS itself is doing it (using png but without transparency)
                    /// to deliver the same experience
                    ///
                    /// We also have to do this request in this batch format
                    /// due to API inconsistency -> check the comment of
                    /// [RequestBatchType.Screenshot]
                    NetworkHelper.makeBatchRequest(
                      networkStore.activeSession!.socket,
                      RequestBatchType.Screenshot,
                      [
                        RequestBatchObject(
                          RequestType.SaveSourceScreenshot,
                          {
                            'sourceName': Hive.box(HiveKeys.Settings.name).get(
                                        SettingsKeys.ExposeStudioControls.name,
                                        defaultValue: false) &&
                                    dashboardStore.studioMode
                                ? dashboardStore.studioModePreviewSceneName
                                : dashboardStore.activeSceneName,
                            'imageFilePath': dashboardStore.screenshotPath,
                            'imageFormat': dashboardStore.previewFileFormat,
                            'compressionQuality': -1,
                          },
                        ),
                        RequestBatchObject(
                          RequestType.GetSourceScreenshot,
                          {
                            'sourceName': Hive.box(HiveKeys.Settings.name).get(
                                        SettingsKeys.ExposeStudioControls.name,
                                        defaultValue: false) &&
                                    dashboardStore.studioMode
                                ? dashboardStore.studioModePreviewSceneName
                                : dashboardStore.activeSceneName,
                            'imageFormat': dashboardStore.previewFileFormat,
                            'compressionQuality': -1,
                          },
                        ),
                      ],
                    );
                  },
                ),
                AppBarActionEntry(
                  title:
                      '${dashboardStore.editSceneVisibility ? 'Finish' : 'Edit'} Scene Visibility',
                  onAction: dashboardStore.editSceneVisibility
                      ? () {
                          dashboardStore.setEditSceneVisibility(false);
                          dashboardStore.setEditSceneItemVisibility(false);
                          dashboardStore.setEditAudioVisibility(false);
                        }
                      : settingsBox.get(
                              SettingsKeys.DontShowHidingScenesWarning.name,
                              defaultValue: false)
                          ? () {
                              dashboardStore.setEditSceneVisibility(true);
                              dashboardStore.setEditSceneItemVisibility(true);
                              dashboardStore.setEditAudioVisibility(true);
                            }
                          : () {
                              ModalHandler.showBaseDialog(
                                context: context,
                                dialogWidget: ConfirmationDialog(
                                  // title: 'Warning on hiding scenes',
                                  // body:
                                  //     'Unfortunately OBS WebSocket only transmits the scene name, nothing else. Therefore I can\'t distinguish between a scene from one specific OBS instance.\n\nUsing a saved connection is advised because then I can bound the scene name to the saved connection - otherwise trying with the ip address which might cause trouble but is still better than nothing!',
                                  title: 'Warning on hiding scene elements',
                                  body:
                                      'Unfortunately OBS WebSocket only gives limit information about scenes and their elements for me to reliably match them with different connections etc.\n\nTo ensure maximum compatibility, please save your connections so I can bound hidden elements to a saved connection.',
                                  enableDontShowAgainOption: true,
                                  noText: 'Cancel',
                                  okText: 'Ok',
                                  onOk: (checked) {
                                    settingsBox.put(
                                        SettingsKeys
                                            .DontShowHidingScenesWarning.name,
                                        checked);
                                    dashboardStore.setEditSceneVisibility(true);
                                    dashboardStore
                                        .setEditSceneItemVisibility(true);
                                    dashboardStore.setEditAudioVisibility(true);
                                  },
                                ),
                              );
                            },
                ),
                AppBarActionEntry(
                  title: '${newConnection ? 'Save' : 'Edit'} Connection',
                  onAction: () {
                    ModalHandler.showBaseDialog(
                      context: context,
                      dialogWidget: SaveEditConnectionDialog(
                        newConnection: newConnection,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
