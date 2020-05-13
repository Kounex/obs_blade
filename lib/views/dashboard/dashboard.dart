import 'package:after_layout/after_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:obs_station/models/connection.dart';
import 'package:obs_station/shared/dialogs/confirmation.dart';
import 'package:obs_station/shared/dialogs/input.dart';
import 'package:obs_station/stores/shared/network.dart';
import 'package:obs_station/stores/views/dashboard.dart';
import 'package:obs_station/types/enums/hive_keys.dart';
import 'package:obs_station/types/enums/request_type.dart';
import 'package:obs_station/utils/routing_helper.dart';
import 'package:obs_station/views/dashboard/widgets/live_status/live_status.dart';
import 'package:obs_station/views/dashboard/widgets/scenes/scenes.dart';
import 'package:provider/provider.dart';

class DashboardView extends StatefulWidget {
  @override
  _DashboardViewState createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> with AfterLayoutMixin {
  @override
  initState() {
    super.initState();
  }

  @override
  void afterFirstLayout(BuildContext context) {
    _checkSaveConnection(context);
  }

  _checkSaveConnection(BuildContext context) {
    NetworkStore networkStore =
        Provider.of<NetworkStore>(context, listen: false);

    if (networkStore.activeSession.connection.name == null) {
      Box<Connection> box =
          Hive.box<Connection>(HiveKeys.SAVED_CONNECTIONS.name);
      showDialog(
        context: context,
        builder: (context) => ConfirmationDialog(
          title: 'Save Connection',
          body:
              'Do you want to save this connection? You can do it later as well.',
          onOk: () {
            showDialog(
              context: context,
              builder: (context) => InputDialog(
                title: 'Save Connection',
                body:
                    'Please choose a name for the connection so you can recognize it later on',
                onSave: (name) {
                  // if the challenge is null, we didn't had to connect with a password
                  // a user might still enter a password, we don't want this password to be
                  // saved, thats why we set it to null explicitly if the challenge (salt could
                  // ne used as well) is null
                  if (networkStore.activeSession.connection.challenge == null) {
                    networkStore.activeSession.connection.pw = null;
                  }
                  networkStore.activeSession.connection.name = name;
                  box.add(networkStore.activeSession.connection);
                },
              ),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    NetworkStore networkStore = Provider.of<NetworkStore>(context);

    return Provider<DashboardStore>(
      create: (_) {
        DashboardStore dashboardStore = DashboardStore();
        dashboardStore.setNetworkStore(networkStore);
        networkStore.makeRequest(RequestType.GetSceneList);
        return dashboardStore;
      },
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        child: Text('Close'),
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => ConfirmationDialog(
                            title: 'Close Connection',
                            body:
                                'Are you sure you want to close the current WebSocket connection?',
                            onOk: () {
                              networkStore.closeSession();
                              Navigator.of(context).pushReplacementNamed(
                                  AppRoutingKeys.LANDING.route);
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 0.0),
                        child: LiveStatus(),
                      ),
                    ],
                  ),
                  Text('Dashboard'),
                ],
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  Scenes(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
