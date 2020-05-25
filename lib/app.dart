import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/settings.dart';
import 'stores/shared/network.dart';
import 'stores/views/landing.dart';
import 'types/enums/hive_keys.dart';
import 'utils/routing_helper.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<LandingStore>(
          create: (_) {
            LandingStore landingStore = LandingStore();

            /// Trigger autodiscover on startup
            landingStore.updateAutodiscoverConnections();
            return landingStore;
          },
        ),
        Provider<NetworkStore>(
          create: (_) => NetworkStore(),
        ),
      ],
      child: ValueListenableBuilder(
        valueListenable:
            Hive.box<Settings>(HiveKeys.SETTINGS.name).listenable(),
        builder: (context, Box<Settings> settingsBox, child) => MaterialApp(
          theme: ThemeData.dark().copyWith(
            accentColor: CupertinoColors.systemBlue, // const Color(0xffb777ff),
            accentIconTheme: IconThemeData(),
            backgroundColor: const Color(0xff101823),
            scaffoldBackgroundColor: settingsBox.getAt(0).trueDark
                ? settingsBox.get(0).reduceSmearing
                    ? Color.fromRGBO(5, 5, 5, 1.0)
                    : Colors.black
                : Colors.grey[900],
            canvasColor: const Color(0xff101823),
            cardColor: const Color(0xff101823),
            dividerColor: Colors.grey[500],
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            appBarTheme: AppBarTheme(
              color: const Color(0xaa101823),
            ),
            buttonTheme: ButtonThemeData(
              buttonColor: const Color(0xffff4654),
              splashColor: Colors.transparent,
            ),
            cupertinoOverrideTheme: CupertinoThemeData(
              textTheme: CupertinoTextThemeData(
                primaryColor: Colors.white,
              ),
              primaryColor: CupertinoColors.systemBlue,
              barBackgroundColor: const Color(0xaa101823),
            ),
          ),
          initialRoute: AppRoutingKeys.TABS.route,
          routes: RoutingHelper.appRoutes,
        ),
      ),
    );
  }
}
