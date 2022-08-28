import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../shared/animator/status_dot.dart';
import '../../../../shared/dialogs/confirmation.dart';
import '../../../../shared/general/flutter_modified/translucent_sliver_app_bar.dart';
import '../../../../shared/general/themed/cupertino_button.dart';
import '../../../../stores/shared/network.dart';
import '../../../../stores/views/dashboard.dart';
import '../../../../utils/modal_handler.dart';
import '../../../../utils/routing_helper.dart';
import 'general_actions.dart';
import 'stream_rec_timers.dart';

class StatusAppBar extends StatelessWidget {
  const StatusAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    return TransculentSliverAppBar(
      pinned: true,
      bottom: PreferredSize(
        child: Column(
          children: const [
            Divider(),
            Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: StreamRecTimers(),
            ),
          ],
        ),
        preferredSize: const Size.fromHeight(24.0),
      ),
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
                      dashboardStore.stopTimers();
                      Navigator.of(context).pushReplacementNamed(
                        HomeTabRoutingKeys.Landing.route,
                        arguments: ModalRoute.of(context)!.settings.arguments,
                      );
                      GetIt.instance<NetworkStore>().closeSession();
                    },
                  ),
                ),
              ),
              const GeneralActions(),
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
                        key: Key(dashboardStore.isLive.toString()),
                        size: 10.0,
                        color: dashboardStore.isLive
                            ? CupertinoColors.activeGreen
                            : CupertinoColors.destructiveRed,
                        text: dashboardStore.isLive ? 'Live' : 'Not Live',
                        style: Theme.of(context).textTheme.caption,
                      ),
                      const SizedBox(width: 8.0),
                      StatusDot(
                        key: Key(
                            '${dashboardStore.isRecording.toString()}+${dashboardStore.isRecordingPaused.toString()}'),
                        size: 10.0,
                        color: dashboardStore.isRecording
                            ? dashboardStore.isRecordingPaused
                                ? CupertinoColors.activeOrange
                                : CupertinoColors.activeGreen
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
