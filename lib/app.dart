import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:obs_station/utils/styling_helper.dart';
import 'package:provider/provider.dart';

import 'models/settings.dart';
import 'stores/shared/network.dart';
import 'stores/views/home.dart';
import 'types/enums/hive_keys.dart';
import 'utils/routing_helper.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<HomeStore>(
          create: (_) {
            HomeStore landingStore = HomeStore();

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
            scaffoldBackgroundColor: settingsBox.getAt(0).trueDark
                ? settingsBox.get(0).reduceSmearing
                    ? StylingHelper.BLACK_REDUCED_SMEARING
                    : Colors.black
                : Colors.grey[900],
            accentColor: CupertinoColors.systemBlue, // const Color(0xffb777ff),
            accentIconTheme: IconThemeData(),
            backgroundColor: StylingHelper.MAIN_BLUE,
            canvasColor: StylingHelper.MAIN_BLUE,
            cardColor: StylingHelper.MAIN_BLUE,
            indicatorColor: CupertinoColors.activeBlue,
            dividerColor: Colors.grey[500],
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            appBarTheme: AppBarTheme(
              color: StylingHelper.MAIN_BLUE.withAlpha(170),
            ),
            buttonTheme: ButtonThemeData(
              buttonColor: StylingHelper.MAIN_RED,
              splashColor: Colors.transparent,
            ),
            cupertinoOverrideTheme: CupertinoThemeData(
              textTheme: CupertinoTextThemeData(
                primaryColor: Colors.white,
              ),
              primaryColor: CupertinoColors.systemBlue,
              barBackgroundColor: StylingHelper.MAIN_BLUE.withAlpha(170),
            ),
          ),
          initialRoute: AppRoutingKeys.TABS.route,
          routes: RoutingHelper.appRoutes,
        ),
      ),
    );
  }
}
