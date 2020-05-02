import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_station/stores/views/landing.dart';
import 'package:obs_station/stores/shared/network.dart';

import 'package:obs_station/utils/routing_helper.dart';
import 'package:obs_station/views/landing/landing.dart';
import 'package:provider/provider.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<LandingStore>(
          create: (_) {
            LandingStore landingStore = LandingStore();
            landingStore.updateAutodiscoverConnections();
            return landingStore;
          },
        ),
        Provider<NetworkStore>(
          create: (_) => NetworkStore(),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData.dark().copyWith(
          cupertinoOverrideTheme: CupertinoThemeData(
            textTheme: CupertinoTextThemeData(primaryColor: Colors.white),
          ),
        ),
        initialRoute: AppRoutingKeys.LANDING.route,
        routes: RoutingHelper.routes,
      ),
    );
  }
}
