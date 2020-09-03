import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

import 'stores/shared/network.dart';
import 'types/enums/hive_keys.dart';
import 'types/enums/settings_keys.dart';
import 'utils/routing_helper.dart';
import 'utils/styling_helper.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Provider<NetworkStore>(
      create: (_) => NetworkStore(),
      child: ValueListenableBuilder(
        valueListenable: Hive.box(HiveKeys.Settings.name).listenable(keys: [
          SettingsKeys.TrueDark.name,
          SettingsKeys.ReduceSmearing.name
        ]),
        builder: (context, Box settingsBox, child) {
          ThemeData theme = ThemeData.dark().copyWith(
            /// General Theme colors
            scaffoldBackgroundColor:
                settingsBox.get(SettingsKeys.TrueDark.name, defaultValue: false)
                    ? settingsBox.get(SettingsKeys.ReduceSmearing.name,
                            defaultValue: false)
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
            toggleableActiveColor: StylingHelper.MAIN_RED,

            /// Inner Widget themes
            appBarTheme: AppBarTheme(
              color: StylingHelper.MAIN_BLUE
                  .withOpacity(StylingHelper.OPACITY_BLURRY),
            ),
            buttonTheme: ButtonThemeData(
              buttonColor: StylingHelper.MAIN_RED,
              splashColor: Colors.transparent,
            ),
            tooltipTheme: TooltipThemeData(
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12.0),
              ),
              textStyle: TextStyle(color: Colors.white),
            ),
            cupertinoOverrideTheme: CupertinoThemeData(
              textTheme: CupertinoTextThemeData(
                primaryColor: Colors.white,
              ),
              primaryColor: CupertinoColors.systemBlue,
              barBackgroundColor: StylingHelper.MAIN_BLUE
                  .withOpacity(StylingHelper.OPACITY_BLURRY),
            ),
          );
          // theme = theme.copyWith(
          //   textTheme: theme.textTheme.copyWith(
          //     bodyText2: theme.textTheme.bodyText2.copyWith(fontSize: 18.0),
          //   ),
          // );
          return MaterialApp(
            theme: theme,
            initialRoute: settingsBox.get(SettingsKeys.HasUserSeenIntro.name,
                    defaultValue: false)
                ? AppRoutingKeys.Tabs.route
                : AppRoutingKeys.Intro.route,
            onGenerateInitialRoutes: (initialRoute) => [
              MaterialWithModalsPageRoute(
                builder: RoutingHelper.appRoutes[initialRoute],
                settings: RouteSettings(name: initialRoute),
              ),
            ],
            routes: RoutingHelper.appRoutes,
          );
        },
      ),
    );
  }
}
