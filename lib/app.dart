import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:obs_blade/stores/shared/tabs.dart';
import 'package:provider/provider.dart';

import 'stores/shared/network.dart';
import 'types/enums/hive_keys.dart';
import 'types/enums/settings_keys.dart';
import 'utils/routing_helper.dart';
import 'utils/styling_helper.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<NetworkStore>(create: (_) => NetworkStore()),
        Provider<TabsStore>(create: (_) => TabsStore()),
      ],
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
                        ? StylingHelper.BACKGROUND_REDUCED_SMEARING_COLOR
                        : StylingHelper.BACKGROUND_COLOR
                    : Colors.grey[900],
            accentColor:
                StylingHelper.HIGHLIGHT_COLOR, // const Color(0xffb777ff),
            accentIconTheme: IconThemeData(),
            backgroundColor: StylingHelper.PRIMARY_COLOR,
            canvasColor: StylingHelper.PRIMARY_COLOR,
            cardColor: StylingHelper.PRIMARY_COLOR,
            indicatorColor: CupertinoColors.activeBlue,
            dividerColor: Colors.grey[500],
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            toggleableActiveColor: StylingHelper.ACCENT_COLOR,

            /// Inner Widget themes
            appBarTheme: AppBarTheme(
              color: StylingHelper.PRIMARY_COLOR
                  .withOpacity(StylingHelper.OPACITY_BLURRY),
            ),
            buttonTheme: ButtonThemeData(
              buttonColor: StylingHelper.ACCENT_COLOR,
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
              scaffoldBackgroundColor: settingsBox
                      .get(SettingsKeys.TrueDark.name, defaultValue: false)
                  ? settingsBox.get(SettingsKeys.ReduceSmearing.name,
                          defaultValue: false)
                      ? StylingHelper.BACKGROUND_REDUCED_SMEARING_COLOR
                      : StylingHelper.BACKGROUND_COLOR
                  : Colors.grey[900],
              textTheme: CupertinoTextThemeData(
                primaryColor: Colors.white,
              ),
              primaryColor: StylingHelper.HIGHLIGHT_COLOR,
              barBackgroundColor: StylingHelper.PRIMARY_COLOR
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
              MaterialPageRoute(
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
