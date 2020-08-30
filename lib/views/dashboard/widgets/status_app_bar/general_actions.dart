import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/shared/dialogs/confirmation.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/enums/request_type.dart';
import 'package:obs_blade/utils/dialog_handler.dart';
import 'package:obs_blade/utils/network_helper.dart';
import 'package:provider/provider.dart';

import '../dialogs/save_edit_connection.dart';

class GeneralActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    NetworkStore networkStore = context.watch<NetworkStore>();
    DashboardStore dashboardStore = context.watch<DashboardStore>();
    return IconButton(
      icon: Icon(
        CupertinoIcons.ellipsis,
        size: 32.0,
      ),
      onPressed: () => showCupertinoModalPopup(
        context: context,
        builder: (context) {
          bool newConnection =
              networkStore.activeSession.connection.name == null;
          return CupertinoActionSheet(
            title: Text('Actions'),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(context).pop();
                  DialogHandler.showBaseDialog(
                      context: context,
                      dialogWidget: ConfirmationDialog(
                          title: dashboardStore.isLive
                              ? 'Stop Streaming'
                              : 'Start Streaming',
                          body: dashboardStore.isLive
                              ? 'Are you sure you want to stop the stream? Nothing more to show or talk about? Or just tired or no time?\n\n... just to make sure it\'s intentional!'
                              : 'Are you sure you are ready to start the stream? Everything done? Stream title and description updated?\n\nIf yes: let\'s go!',
                          isYesDestructive: true,
                          onOk: () => NetworkHelper.makeRequest(
                              networkStore.activeSession.socket,
                              RequestType.StartStopStreaming)));
                },
                child: Text(dashboardStore.isLive
                    ? 'Stop Streaming'
                    : 'Start Streaming'),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(context).pop();
                  DialogHandler.showBaseDialog(
                    context: context,
                    dialogWidget: SaveEditConnectionDialog(
                      newConnection: newConnection,
                    ),
                  );
                },
                child: Text((newConnection ? 'Save' : 'Edit') + ' Connection'),
              )
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          );
        },
      ),
    );
  }
}
