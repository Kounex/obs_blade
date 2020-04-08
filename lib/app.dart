import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_station/stores/landing.dart';
import 'package:obs_station/stores/network.dart';

import 'package:obs_station/utils/routing_helper.dart';
import 'package:obs_station/views/landing/landing.dart';
import 'package:provider/provider.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        cupertinoOverrideTheme: CupertinoThemeData(
          textTheme: CupertinoTextThemeData(primaryColor: Colors.white),
        ),
      ),
      routes: RoutingHelper.routes,
      home: MultiProvider(
        providers: [
          Provider<LandingStore>(
            create: (_) => LandingStore(),
          ),
          Provider<NetworkStore>(
            create: (_) => NetworkStore(),
          ),
        ],
        child: LandingView(),
      ),
    );
  }
}
