import 'package:flutter/material.dart';
import 'package:obs_station/shared/basic/status_dot.dart';
import 'package:obs_station/stores/views/dashboard.dart';
import 'package:provider/provider.dart';

class LiveStatus extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = Provider.of<DashboardStore>(context);

    return GestureDetector(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StatusDot(
            color: dashboardStore.isLive ? Colors.green : Colors.red,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              dashboardStore.isLive ? 'Live' : 'Not Live',
              style: Theme.of(context).textTheme.bodyText2,
            ),
          ),
        ],
      ),
      /*
      child: StreamBuilder<dynamic>(
        stream: networkStore.activeSession.socketStream,
        builder: (context, snapshot) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StatusDot(
                color: snapshot.hasData &&
                        json.decode(snapshot.data)['update-type'] !=
                            'StreamStopped'
                    ? Colors.green
                    : Colors.red,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  snapshot.hasData &&
                          json.decode(snapshot.data)['update-type'] !=
                              'StreamStopped'
                      ? 'Live'
                      : 'Not Live',
                  style: Theme.of(context).textTheme.bodyText2,
                ),
              ),
            ],
          );
        },
      ),
      */
    );
  }
}
