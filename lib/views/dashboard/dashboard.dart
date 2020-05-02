import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:obs_station/models/connection.dart';
import 'package:obs_station/shared/dialogs/confirmation.dart';
import 'package:obs_station/stores/shared/network.dart';
import 'package:obs_station/types/enums/hive_keys.dart';
import 'package:obs_station/utils/network_helper.dart';
import 'package:obs_station/utils/routing_helper.dart';
import 'package:obs_station/views/dashboard/widgets/live_status/live_status.dart';
import 'package:provider/provider.dart';

class DashboardView extends StatefulWidget {
  @override
  _DashboardViewState createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  NetworkStore _networkStore;

  @override
  initState() {
    super.initState();
    _networkStore = Provider.of<NetworkStore>(context);
    _checkSaveConnection(context);
  }

  _checkSaveConnection(BuildContext context) {
    if (_networkStore.activeSession.connection.name == null) {
      Box<Connection> box =
          Hive.box<Connection>(HiveKeys.SAVED_CONNECTIONS.name);
      showDialog(
        context: context,
        builder: (context) => Builder(
          builder: (context) => ConfirmationDialog(
              title: 'Save Connection',
              body:
                  'Do you want to save this connection? You can do it later as well.',
              onOk: () => null),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Row(
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
                        _networkStore.closeSession();
                        Navigator.of(context)
                            .pushReplacementNamed(AppRoutingKeys.LANDING.route);
                      },
                    ),
                  ),
                ),
                Text('Dashboard'),
                Padding(
                    padding: const EdgeInsets.only(right: 0.0),
                    child: LiveStatus()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
