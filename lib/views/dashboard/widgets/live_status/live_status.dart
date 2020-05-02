import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:obs_station/stores/shared/network.dart';
import 'package:provider/provider.dart';

class LiveStatus extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    NetworkStore networkStore = Provider.of<NetworkStore>(context);

    return GestureDetector(
      child: StreamBuilder<dynamic>(
        stream: networkStore.activeSession.socketStream,
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
                          json.decode(snapshot.data)['update-type'] !=
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
    );
  }
}
