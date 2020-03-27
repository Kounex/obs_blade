import 'package:flutter/material.dart';
import 'package:mobx_provider/mobx_provider.dart';
import 'package:obs_station/models/landing.dart';
import 'package:obs_station/utils/network_helper.dart';
import 'package:ping_discover_network/ping_discover_network.dart';

class AutoDiscovery extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
            child: Text(
              'Autodiscovery',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headline4
                  .copyWith(color: Colors.white),
            ),
          ),
          Divider(
            height: 0.0,
          ),
          MobxWidgetProvider<LandingStore>(builder: (context, landingStore) {
            return FutureBuilder<List<NetworkAddress>>(
              future: landingStore.obsNetworkAddresses,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasData) {
                    List<NetworkAddress> result = snapshot.data
                        .where((networkAddress) => networkAddress.exists)
                        .toList();
                    if (result.length > 0) {}
                    return Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.only(left: 24.0, right: 24.0),
                      height: 150.0,
                      child: Text(
                        'Could not find an open OBS session via autodiscovery! Make sure you have an open OBS session in your local network with the OBS WebSocket plugin installed!\n\nPull down to try again!',
                        textAlign: TextAlign.center,
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.only(left: 24.0, right: 24.0),
                      height: 150.0,
                      child: Text(
                        'Could not finish autodiscovery! Make sure you are connected to your local network!\n\nPull down to try again!',
                        textAlign: TextAlign.center,
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
          }),
        ],
      ),
    );
  }
}
