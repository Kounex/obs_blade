import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:obs_blade/shared/general/themed/themed_cupertino_button.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:provider/provider.dart';

import '../../../../shared/general/flutter_modified/translucent_sliver_app_bar.dart';
import '../../../../shared/animator/status_dot.dart';
import '../../../../shared/dialogs/confirmation.dart';
import '../../../../stores/shared/network.dart';
import '../../../../stores/views/dashboard.dart';
import '../../../../utils/routing_helper.dart';
import 'general_actions.dart';

class StatusAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = context.watch<DashboardStore>();

    return TransculentSliverAppBar(
      pinned: true,
      title: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ThemedCupertinoButton(
                text: 'Close',
                onPressed: () => ModalHandler.showBaseDialog(
                  context: context,
                  dialogWidget: ConfirmationDialog(
                    title: 'Close Connection',
                    body:
                        'Are you sure you want to close the current WebSocket connection?',
                    isYesDestructive: true,
                    onOk: (_) {
                      dashboardStore.finishPastStreamData();
                      Navigator.of(context).pushReplacementNamed(
                        HomeTabRoutingKeys.Landing.route,
                        arguments: ModalRoute.of(context).settings.arguments,
                      );
                      context.read<NetworkStore>().closeSession();
                    },
                  ),
                ),
              ),
              GeneralActions(),
            ],
          ),
          Column(
            children: <Widget>[
              Text(
                'Dashboard',
                style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2.0, bottom: 2.0),
                child: Observer(builder: (_) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      StatusDot(
                        key: Key(dashboardStore.isLive?.toString()),
                        size: 10.0,
                        color: dashboardStore.isLive
                            ? Colors.green
                            : CupertinoColors.destructiveRed,
                        text: dashboardStore.isLive ? 'Live' : 'Not Live',
                        style: Theme.of(context).textTheme.caption,
                      ),
                      SizedBox(width: 8.0),
                      StatusDot(
                        key: Key(
                            '${dashboardStore.isRecording?.toString()}+${dashboardStore.isRecordingPaused?.toString()}'),
                        size: 10.0,
                        color: dashboardStore.isRecording
                            ? dashboardStore.isRecordingPaused
                                ? Colors.orange
                                : Colors.green
                            : CupertinoColors.destructiveRed,
                        text: dashboardStore.isRecording
                            ? dashboardStore.isRecordingPaused
                                ? 'Paused Recording'
                                : 'Recording'
                            : 'Not Recording',
                        style: Theme.of(context).textTheme.caption,
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
