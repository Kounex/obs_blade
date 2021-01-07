import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:obs_blade/models/connection.dart';
import 'package:obs_blade/shared/dialogs/confirmation.dart';
import 'package:obs_blade/shared/general/app_bar_cupertino_actions.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/request_type.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:obs_blade/utils/network_helper.dart';
import 'package:provider/provider.dart';

import '../save_edit_connection_dialog.dart';

class GeneralActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    NetworkStore networkStore = context.watch<NetworkStore>();
    DashboardStore dashboardStore = context.watch<DashboardStore>();

    return ValueListenableBuilder(
      valueListenable:
          Hive.box<Connection>(HiveKeys.SavedConnections.name).listenable(),
      builder: (context, savedConnectionsBox, _) {
        bool newConnection =
            networkStore.activeSession?.connection?.name == null;
        return Observer(
          builder: (_) => AppBarCupertinoActions(
            actions: [
              AppBarCupertinoActionEntry(
                title:
                    (dashboardStore.isLive ? 'Stop' : 'Start') + ' Streaming',
                onAction: () {
                  ModalHandler.showBaseDialog(
                    context: context,
                    dialogWidget: ConfirmationDialog(
                      title: (dashboardStore.isLive ? 'Stop' : 'Start') +
                          ' Streaming',
                      body: dashboardStore.isLive
                          ? 'Are you sure you want to stop the stream? Nothing more to show or talk about? Or just tired or no time?\n\n... just to make sure it\'s intentional!'
                          : 'Are you sure you are ready to start the stream? Everything done? Stream title and description updated?\n\nIf yes: let\'s go!',
                      isYesDestructive: true,
                      onOk: (_) => NetworkHelper.makeRequest(
                          networkStore.activeSession.socket,
                          RequestType.StartStopStreaming),
                    ),
                  );
                },
              ),
              AppBarCupertinoActionEntry(
                title: (dashboardStore.isRecording ? 'Stop' : 'Start') +
                    ' Recording',
                onAction: () {
                  ModalHandler.showBaseDialog(
                    context: context,
                    dialogWidget: ConfirmationDialog(
                      title: (dashboardStore.isRecording ? 'Stop' : 'Start') +
                          ' Recording',
                      body: dashboardStore.isRecording
                          ? 'Do you want to stop recording? Got everything on tape as intended?\n\nIf yes: nice work!'
                          : 'Do you want to start recording? Recording unintentionally is not as bad as suddenly starting to stream!\n\nStill asking just to be sure!',
                      isYesDestructive: true,
                      onOk: (_) => NetworkHelper.makeRequest(
                          networkStore.activeSession.socket,
                          RequestType.StartStopRecording),
                    ),
                  );
                },
              ),
              AppBarCupertinoActionEntry(
                title: (dashboardStore.isRecordingPaused ? 'Resume' : 'Pause') +
                    ' Recording',
                onAction: dashboardStore.isRecording
                    ? () => NetworkHelper.makeRequest(
                          networkStore.activeSession.socket,
                          dashboardStore.isRecordingPaused
                              ? RequestType.ResumeRecording
                              : RequestType.PauseRecording,
                        )
                    : null,
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
        );
      },
    );
  }
}
