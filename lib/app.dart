import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_station/stores/views/landing.dart';
import 'package:obs_station/stores/shared/network.dart';

import 'package:obs_station/utils/routing_helper.dart';
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
          backgroundColor: const Color(0xff101823),
          scaffoldBackgroundColor: Colors.black, //const Color(0xff181818),
          canvasColor: const Color(0xff101823),
          cardColor: const Color(0xff101823),
          dividerColor: Colors.grey[500],
          appBarTheme: AppBarTheme(
            color: const Color(0xff101823),
          ),
          buttonTheme: ButtonThemeData(
            buttonColor: const Color(0xffff4654),
          ),
          cupertinoOverrideTheme: CupertinoThemeData(
            textTheme: CupertinoTextThemeData(
              primaryColor: Colors.white,
            ),
          ),
        ),
        initialRoute: AppRoutingKeys.LANDING.route,
        routes: RoutingHelper.routes,
      ),
    );
  }
}
