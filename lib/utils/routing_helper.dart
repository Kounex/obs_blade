import 'package:flutter/material.dart';

import '../tab_base.dart';
import '../views/about/about.dart';
import '../views/dashboard/dashboard.dart';
import '../views/home/home.dart';
import '../views/settings/settings.dart';

/// all routing keys available on root level - for now the whole app
/// is wrapped in tabs and no other root level views (which are not inside
/// those tabs) are used
enum AppRoutingKeys { TABS }

/// routing keys for the home tab
enum HomeTabRoutingKeys {
  LANDING,
  DASHBOARD,
}

/// routing keys for the settings tab
enum SettingsTabRoutingKeys {
  LANDING,
  ABOUT,
}

/// extension method for [AppRoutingKeys] enum to get the actual route
/// path for an enum
extension AppRoutingKeysFunctions on AppRoutingKeys {
  String get route => const {
        AppRoutingKeys.TABS: '/tabs',
      }[this];
}

/// extension method for [HomeTabRoutingKeys] enum to get the actual route
/// path for an enum
extension HomeTabRoutingKeysFunctions on HomeTabRoutingKeys {
  String get route => {
        HomeTabRoutingKeys.LANDING: AppRoutingKeys.TABS.route + '/home',
        HomeTabRoutingKeys.DASHBOARD:
            AppRoutingKeys.TABS.route + '/home/dashboard',
      }[this];
}

/// extension method for [SettingsTabRoutingKeys] enum to get the actual route
/// path for an enum
extension SettingsTabRoutingKeysFunctions on SettingsTabRoutingKeys {
  String get route => {
        SettingsTabRoutingKeys.LANDING: AppRoutingKeys.TABS.route + '/settings',
        SettingsTabRoutingKeys.ABOUT:
            AppRoutingKeys.TABS.route + '/settings/about',
      }[this];
}

/// Used to summarize routing tasks and information at one point
class RoutingHelper {
  static Map<String, Widget Function(BuildContext)> homeTabRoutes = {
    HomeTabRoutingKeys.LANDING.route: (_) => HomeView(),
    HomeTabRoutingKeys.DASHBOARD.route: (_) => DashboardView(),
  };

  static Map<String, Widget Function(BuildContext)> settingsTabRoutes = {
    SettingsTabRoutingKeys.LANDING.route: (_) => SettingsView(),
    SettingsTabRoutingKeys.ABOUT.route: (_) => AboutView(),
  };

  static Map<String, Widget Function(BuildContext)> appRoutes = {
    AppRoutingKeys.TABS.route: (_) => TabBase(),
  };
}
