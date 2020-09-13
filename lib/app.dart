import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/custom_theme.dart';
import 'stores/shared/network.dart';
import 'stores/shared/tabs.dart';
import 'types/enums/hive_keys.dart';
import 'types/enums/settings_keys.dart';
import 'utils/routing_helper.dart';
import 'utils/styling_helper.dart';
import 'types/extensions/string.dart';

class App extends StatelessWidget {
  ThemeData _getCurrentTheme(Box settingsBox) {
    Color scaffoldBackgroundColor;
    Color accentColor;
    Color backgroundColor;
    Color canvasColor;
    Color cardColor;
    Color indicatorColor;
    Color toggleableActiveColor;
    Color appBarColor;
    Color buttonColor;
    Color tabBarColor;
    Color cupertinoPrimaryColor;

    if (settingsBox.get(SettingsKeys.CustomTheme.name, defaultValue: false)) {
      CustomTheme activeCustomTheme =
          Hive.box<CustomTheme>(HiveKeys.CustomTheme.name).values.firstWhere(
              (customTheme) =>
                  customTheme.uuid ==
                  settingsBox.get(SettingsKeys.ActiveCustomThemeUUID.name,
                      defaultValue: ''),
              orElse: () => null);
      if (activeCustomTheme != null) {
        scaffoldBackgroundColor =
            activeCustomTheme.backgroundColorHex.hexToColor();
        accentColor = activeCustomTheme.highlightColorHex.hexToColor();
        backgroundColor = activeCustomTheme.cardColorHex.hexToColor();
        canvasColor = activeCustomTheme.cardColorHex.hexToColor();
        cardColor = activeCustomTheme.cardColorHex.hexToColor();
        indicatorColor = activeCustomTheme.highlightColorHex.hexToColor();
        toggleableActiveColor = activeCustomTheme.accentColorHex.hexToColor();
        appBarColor = activeCustomTheme.appBarColorHex.hexToColor();
        buttonColor = activeCustomTheme.accentColorHex.hexToColor();
        tabBarColor = activeCustomTheme.tabBarColorHex.hexToColor();
        cupertinoPrimaryColor =
            activeCustomTheme.highlightColorHex.hexToColor();
      }
    }

    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: scaffoldBackgroundColor ??
          (settingsBox.get(SettingsKeys.TrueDark.name, defaultValue: false)
              ? settingsBox.get(SettingsKeys.ReduceSmearing.name,
                      defaultValue: false)
                  ? StylingHelper.BACKGROUND_REDUCED_SMEARING_COLOR
                  : StylingHelper.BACKGROUND_COLOR
              : Colors.grey[900]),
      accentColor: accentColor ?? StylingHelper.HIGHLIGHT_COLOR,
      backgroundColor: backgroundColor ?? StylingHelper.PRIMARY_COLOR,
      canvasColor: canvasColor ?? StylingHelper.PRIMARY_COLOR,
      cardColor: cardColor ?? StylingHelper.PRIMARY_COLOR,
      indicatorColor: indicatorColor ?? StylingHelper.HIGHLIGHT_COLOR,
      dividerColor: Colors.grey[500],
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      toggleableActiveColor:
          toggleableActiveColor ?? StylingHelper.ACCENT_COLOR,

      /// Inner Widget themes
      appBarTheme: AppBarTheme(
        color: (appBarColor ?? StylingHelper.PRIMARY_COLOR)
            .withOpacity(StylingHelper.OPACITY_BLURRY),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: buttonColor ?? StylingHelper.ACCENT_COLOR,
        splashColor: Colors.transparent,
      ),
      // tooltipTheme: TooltipThemeData(
      //   decoration: BoxDecoration(
      //     color: Colors.grey[800],
      //     borderRadius: BorderRadius.circular(12.0),
      //   ),
      //   textStyle: TextStyle(color: Colors.white),
      // ),
      cupertinoOverrideTheme: CupertinoThemeData(
        scaffoldBackgroundColor: scaffoldBackgroundColor ??
            (settingsBox.get(SettingsKeys.TrueDark.name, defaultValue: false)
                ? settingsBox.get(SettingsKeys.ReduceSmearing.name,
                        defaultValue: false)
                    ? StylingHelper.BACKGROUND_REDUCED_SMEARING_COLOR
                    : StylingHelper.BACKGROUND_COLOR
                : Colors.grey[900]),
        textTheme: CupertinoTextThemeData(
          primaryColor: Colors.white,
        ),
        primaryColor: cupertinoPrimaryColor ?? StylingHelper.HIGHLIGHT_COLOR,
        barBackgroundColor: (tabBarColor ?? StylingHelper.PRIMARY_COLOR)
            .withOpacity(StylingHelper.OPACITY_BLURRY),
      ),
    );
  }

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
          SettingsKeys.ReduceSmearing.name,
          SettingsKeys.CustomTheme.name,
          SettingsKeys.ActiveCustomThemeUUID.name,
        ]),
        builder: (context, Box settingsBox, child) {
          return MaterialApp(
            theme: _getCurrentTheme(settingsBox),
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
