import 'package:flutter/material.dart';
import 'package:obs_blade/views/privacy_policy/privacy_policy.dart';
import 'package:obs_blade/views/statistics/statistics.dart';

import '../tab_base.dart';
import '../views/about/about.dart';
import '../views/dashboard/dashboard.dart';
import '../views/home/home.dart';
import '../views/settings/settings.dart';

/// All routing keys available on root level - for now the whole app
/// is wrapped in tabs and no other root level views (which are not inside
/// those tabs) are used
enum AppRoutingKeys { Tabs }

/// Routing keys for the home tab
enum HomeTabRoutingKeys {
  Landing,
  Dashboard,
}

/// Routing keys for the statistics tab
enum StaticticsTabRoutingKeys {
  Landing,
}

/// Routing keys for the settings tab
enum SettingsTabRoutingKeys {
  Landing,
  PrivacyPolicy,
  About,
}

/// Extension method for [AppRoutingKeys] enum to get the actual route
/// path for an enum
extension AppRoutingKeysFunctions on AppRoutingKeys {
  String get route => const {
        AppRoutingKeys.Tabs: '/tabs',
      }[this];
}

/// Extension method for [HomeTabRoutingKeys] enum to get the actual route
/// path for an enum
extension HomeTabRoutingKeysFunctions on HomeTabRoutingKeys {
  String get route => {
        HomeTabRoutingKeys.Landing: AppRoutingKeys.Tabs.route + '/home',
        HomeTabRoutingKeys.Dashboard:
            AppRoutingKeys.Tabs.route + '/home/dashboard',
      }[this];
}

/// Extension method for [StaticticsTabRoutingKeys] enum to get the actual route
/// path for an enum
extension StaticticsTabRoutingKeysFunctions on StaticticsTabRoutingKeys {
  String get route => {
        StaticticsTabRoutingKeys.Landing:
            AppRoutingKeys.Tabs.route + '/statistics',
      }[this];
}

/// Extension method for [SettingsTabRoutingKeys] enum to get the actual route
/// path for an enum
extension SettingsTabRoutingKeysFunctions on SettingsTabRoutingKeys {
  String get route => {
        SettingsTabRoutingKeys.Landing: AppRoutingKeys.Tabs.route + '/settings',
        SettingsTabRoutingKeys.PrivacyPolicy:
            AppRoutingKeys.Tabs.route + '/settings/privacy_policy',
        SettingsTabRoutingKeys.About:
            AppRoutingKeys.Tabs.route + '/settings/about',
      }[this];
}

/// Used to summarize routing tasks and information at one point
class RoutingHelper {
  static Map<String, Widget Function(BuildContext)> homeTabRoutes = {
    HomeTabRoutingKeys.Landing.route: (_) => HomeView(),
    HomeTabRoutingKeys.Dashboard.route: (_) => DashboardView(),
  };

  static Map<String, Widget Function(BuildContext)> statisticsTabRoutes = {
    StaticticsTabRoutingKeys.Landing.route: (_) => StatisticsView(),
  };

  static Map<String, Widget Function(BuildContext)> settingsTabRoutes = {
    SettingsTabRoutingKeys.Landing.route: (_) => SettingsView(),
    SettingsTabRoutingKeys.PrivacyPolicy.route: (_) => PrivacyPolicyView(),
    SettingsTabRoutingKeys.About.route: (_) => AboutView(),
  };

  static Map<String, Widget Function(BuildContext)> appRoutes = {
    AppRoutingKeys.Tabs.route: (_) => TabBase(),
  };
}
