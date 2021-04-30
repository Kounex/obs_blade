import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:obs_blade/shared/general/hive_builder.dart';
import 'package:provider/provider.dart';

import '../../../../models/connection.dart';
import '../../../../shared/dialogs/confirmation.dart';
import '../../../../shared/general/app_bar_cupertino_actions.dart';
import '../../../../stores/shared/network.dart';
import '../../../../stores/views/dashboard.dart';
import '../../../../types/enums/hive_keys.dart';
import '../../../../types/enums/request_type.dart';
import '../../../../types/enums/settings_keys.dart';
import '../../../../utils/modal_handler.dart';
import '../../../../utils/network_helper.dart';
import '../../services/record_stream.dart';
import '../save_edit_connection_dialog.dart';

class GeneralActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    NetworkStore networkStore = context.read<NetworkStore>();
    DashboardStore dashboardStore = context.read<DashboardStore>();

    return HiveBuilder<Connection>(
      hiveKey: HiveKeys.SavedConnections,
      builder: (context, savedConnectionsBox, child) {
        bool newConnection =
            networkStore.activeSession?.connection.name == null;
        return HiveBuilder<dynamic>(
          hiveKey: HiveKeys.Settings,
          rebuildKeys: [
            SettingsKeys.ExposeStreamingControls,
            SettingsKeys.ExposeRecordingControls,
            SettingsKeys.DontShowHidingScenesWarning,
            SettingsKeys.DontShowRecordStartMessage,
            SettingsKeys.DontShowRecordStopMessage,
            SettingsKeys.DontShowStreamStartMessage,
            SettingsKeys.DontShowStreamStopMessage,
          ],
          builder: (context, settingsBox, child) => Observer(
            builder: (_) => AppBarCupertinoActions(
              actions: [
                if (!settingsBox.get(SettingsKeys.ExposeStreamingControls.name,
                    defaultValue: false))
                  AppBarCupertinoActionEntry(
                    title: (dashboardStore.isLive ? 'Stop' : 'Start') +
                        ' Streaming',
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
                  AppBarCupertinoActionEntry(
                    title: (dashboardStore.isRecording ? 'Stop' : 'Start') +
                        ' Recording',
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
                  AppBarCupertinoActionEntry(
                    title: (dashboardStore.isRecordingPaused
                            ? 'Resume'
                            : 'Pause') +
                        ' Recording',
                    onAction: dashboardStore.isRecording
                        ? () => NetworkHelper.makeRequest(
                              networkStore.activeSession!.socket,
                              dashboardStore.isRecordingPaused
                                  ? RequestType.ResumeRecording
                                  : RequestType.PauseRecording,
                            )
                        : null,
                  ),
                ],
                AppBarCupertinoActionEntry(
                  title:
                      (dashboardStore.editSceneVisibility ? 'Finish' : 'Edit') +
                          ' Scene Visibility',
                  onAction: dashboardStore.editSceneVisibility
                      ? () => dashboardStore.setEditSceneVisibility(false)
                      : settingsBox.get(
                              SettingsKeys.DontShowHidingScenesWarning.name,
                              defaultValue: false)
                          ? () => dashboardStore.setEditSceneVisibility(true)
                          : () {
                              ModalHandler.showBaseDialog(
                                context: context,
                                dialogWidget: ConfirmationDialog(
                                  title: 'Warning on hiding scenes',
                                  body:
                                      'Unfortunately OBS WebSocket only transmits the scene name, nothing else. Therefore I can\'t distinguish between a scene from one specific OBS instance.\n\nUsing a saved connection is advised because then I can bound the scene name to the saved connection - otherwise trying with the ip address which might cause trouble but is still better than nothing!',
                                  enableDontShowAgainOption: true,
                                  noText: 'Cancel',
                                  okText: 'Ok',
                                  onOk: (checked) {
                                    settingsBox.put(
                                        SettingsKeys
                                            .DontShowHidingScenesWarning.name,
                                        checked);
                                    dashboardStore.setEditSceneVisibility(true);
                                  },
                                ),
                              );
                            },
                ),
                AppBarCupertinoActionEntry(
                  title: (newConnection ? 'Save' : 'Edit') + ' Connection',
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
