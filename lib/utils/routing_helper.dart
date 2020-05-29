import 'package:flutter/material.dart';

import '../tab_base.dart';
import '../views/about/about.dart';
import '../views/dashboard/dashboard.dart';
import '../views/home/home.dart';
import '../views/settings/settings.dart';

enum AppRoutingKeys { TABS }

enum HomeTabRoutingKeys {
  LANDING,
  DASHBOARD,
}

enum SettingsTabRoutingKeys {
  LANDING,
  ABOUT,
}

extension AppRoutingKeysFunctions on AppRoutingKeys {
  String get route => const {
        AppRoutingKeys.TABS: '/tabs',
      }[this];
}

extension HomeTabRoutingKeysFunctions on HomeTabRoutingKeys {
  String get route => {
        HomeTabRoutingKeys.LANDING: AppRoutingKeys.TABS.route + '/home',
        HomeTabRoutingKeys.DASHBOARD:
            AppRoutingKeys.TABS.route + '/home/dashboard',
      }[this];
}

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
