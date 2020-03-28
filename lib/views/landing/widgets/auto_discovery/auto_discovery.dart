import 'package:flutter/material.dart';
import 'package:mobx_provider/mobx_provider.dart';
import 'package:obs_station/models/landing.dart';
import 'package:obs_station/shared/fade_inner.dart';
import 'package:obs_station/views/landing/widgets/auto_discovery/session_tile.dart';

class AutoDiscovery extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MobxWidgetProvider<LandingStore>(builder: (context, landingStore) {
      return FutureBuilder<List<String>>(
        future: landingStore.obsAutodiscoverIPs,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              if (snapshot.data.length > 0) {
                return FadeInner(
                  child: Column(
                    children: snapshot.data
                        .map(
                            (availableObsIP) => SessionTile(ip: availableObsIP))
                        .toList(),
                  ),
                );
              }
              return Container(
                padding: EdgeInsets.only(left: 24.0, right: 24.0),
                alignment: Alignment.center,
                height: 150.0,
                child: FadeInner(
                  child: Text(
                    'Could not find an open OBS session via autodiscovery! Make sure you have an open OBS session in your local network with the OBS WebSocket plugin installed!\n\nPull down to try again!',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            } else if (snapshot.hasError) {
              return Container(
                padding: EdgeInsets.only(left: 24.0, right: 24.0),
                alignment: Alignment.center,
                height: 150.0,
                child: FadeInner(
                  child: Text(
                    'Network error occured! Make sure you are connected to your local network!\n\nPull down to try again!',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
          }
          return Align(
            child: Container(
              height: 150.0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CircularProgressIndicator(
                    strokeWidth: 2.0,
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 12.0),
                    child: Text('Searching...'),
                  )
                ],
              ),
            ),
          );
        },
      );
    });
  }
}
