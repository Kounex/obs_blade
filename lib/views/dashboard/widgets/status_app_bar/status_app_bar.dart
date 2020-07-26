import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../../../shared/basic/flutter_modified/translucent_sliver_app_bar.dart';
import '../../../../shared/basic/status_dot.dart';
import '../../../../shared/dialogs/confirmation.dart';
import '../../../../stores/shared/network.dart';
import '../../../../stores/views/dashboard.dart';
import '../../../../utils/routing_helper.dart';
import 'general_actions.dart';

class StatusAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TransculentSliverAppBar(
      pinned: true,
      title: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CupertinoButton(
                child: Text('Close'),
                onPressed: () => showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => ConfirmationDialog(
                    title: 'Close Connection',
                    body:
                        'Are you sure you want to close the current WebSocket connection?',
                    isYesDestructive: true,
                    onOk: () {
                      context.read<NetworkStore>().closeSession();
                      Navigator.of(context).pushReplacementNamed(
                          HomeTabRoutingKeys.Landing.route);
                    },
                  ),
                ),
              ),
              GeneralActions(),
            ],
          ),
          Column(
            children: <Widget>[
              Text('Dashboard'),
              Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                child: Observer(builder: (_) {
                  return StatusDot(
                    size: 8.0,
                    color: context.read<DashboardStore>().isLive
                        ? Colors.green
                        : Colors.red,
                    text: context.read<DashboardStore>().isLive
                        ? 'Live'
                        : 'Not Live',
                    style: Theme.of(context).textTheme.caption,
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
