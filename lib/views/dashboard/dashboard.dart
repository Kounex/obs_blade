import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_station/stores/shared/network.dart';
import 'package:obs_station/utils/network_helper.dart';
import 'package:obs_station/utils/routing_helper.dart';
import 'package:provider/provider.dart';

class DashboardView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    NetworkStore networkStore = Provider.of<NetworkStore>(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            leading: CupertinoButton(
              child: Text('Close'),
              onPressed: () {
                networkStore.closeSession();
                Navigator.of(context)
                    .pushReplacementNamed(AppRoutingKeys.LANDING.route);
              },
            ),
            title: Text('Dashboard'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 24.0),
                child: GestureDetector(
                  child: StreamBuilder<dynamic>(
                      stream:
                          networkStore.activeSession.socketStreamSubscription,
                      builder: (context, snapshot) {
                        print(snapshot.data);
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 12.0,
                              height: 12.0,
                              decoration: BoxDecoration(
                                color: snapshot.hasData &&
                                        json.decode(
                                                snapshot.data)['update-type'] !=
                                            'StreamStopped'
                                    ? Colors.green
                                    : Colors.red,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12.0),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(snapshot.hasData &&
                                      json.decode(
                                              snapshot.data)['update-type'] !=
                                          'StreamStopped'
                                  ? 'Live'
                                  : 'Not Live'),
                            ),
                          ],
                        );
                      }),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
