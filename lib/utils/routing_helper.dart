import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/views/settings/logs/log_detail/log_detail.dart';

import '../tab_base.dart';
import '../views/dashboard/dashboard.dart';
import '../views/home/home.dart';
import '../views/intro/intro.dart';
import '../views/settings/about/about.dart';
import '../views/settings/custom_theme/custom_theme.dart';
import '../views/settings/data_management/data_management.dart';
import '../views/settings/faq/faq.dart';
import '../views/settings/logs/logs.dart';
import '../views/settings/privacy_policy/privacy_policy.dart';
import '../views/settings/settings.dart';
import '../views/statistics/statistic_detail/statistic_detail.dart';
import '../views/statistics/statistics.dart';

/// All routing keys available on root level - for now the whole app
/// is wrapped in tabs and no other root level views (which are not inside
/// those tabs) are used
enum AppRoutingKeys {
  Intro,
  Tabs,
}

/// All available and used tabs in our TabView which is basically the root
/// of our application (view wise) since the main navigation is realised
/// with a tab bar - this enum is used to iterate over available tabs and
/// automate adding tabs (see extension functions for this enum)
enum Tabs {
  Home,
  Statistics,
  Settings,
}

/// Extension functions for the [Tabs] enum which has some convinient functions
/// which automates the generation of the [Navigator] instances with the
/// needed properties in [TabBase]. By populating the enum and this functions
/// current and new tabs will automatically generated / changed
extension TabsFunctions on Tabs {
  String get name => const {
        Tabs.Home: 'Home',
        Tabs.Statistics: 'Statistics',
        Tabs.Settings: 'Settings',
      }[this]!;

  IconData get icon => const {
        Tabs.Home: CupertinoIcons.house_alt,
        Tabs.Statistics: CupertinoIcons.chart_bar_alt_fill,
        Tabs.Settings: CupertinoIcons.settings,
      }[this]!;

  Map<String, Widget Function(BuildContext)> get routes => {
        Tabs.Home: RoutingHelper.homeTabRoutes,
        Tabs.Statistics: RoutingHelper.statisticsTabRoutes,
        Tabs.Settings: RoutingHelper.settingsTabRoutes,
      }[this]!;
}

/// Routing keys for the home tab
enum HomeTabRoutingKeys {
  Landing,
  Dashboard,
}

/// Routing keys for the statistics tab
enum StaticticsTabRoutingKeys {
  Landing,
  Detail,
}

/// Routing keys for the settings tab
enum SettingsTabRoutingKeys {
  Landing,
  PrivacyPolicy,
  About,
  CustomTheme,
  FAQ,
  DataManagement,
  Logs,
  LogDetail,
}

/// Extension method for [AppRoutingKeys] enum to get the actual route
/// path for an enum
extension AppRoutingKeysFunctions on AppRoutingKeys {
  String get route => const {
        AppRoutingKeys.Intro: '/intro',
        AppRoutingKeys.Tabs: '/tabs',
      }[this]!;
}

/// Extension method for [HomeTabRoutingKeys] enum to get the actual route
/// path for an enum
extension HomeTabRoutingKeysFunctions on HomeTabRoutingKeys {
  String get route => {
        HomeTabRoutingKeys.Landing: AppRoutingKeys.Tabs.route + '/home',
        HomeTabRoutingKeys.Dashboard:
            AppRoutingKeys.Tabs.route + '/home/dashboard',
      }[this]!;
}

/// Extension method for [StaticticsTabRoutingKeys] enum to get the actual route
/// path for an enum
extension StaticticsTabRoutingKeysFunctions on StaticticsTabRoutingKeys {
  String get route => {
        StaticticsTabRoutingKeys.Landing:
            AppRoutingKeys.Tabs.route + '/statistics',
        StaticticsTabRoutingKeys.Detail:
            AppRoutingKeys.Tabs.route + '/statistics/detail',
      }[this]!;
}

/// Extension method for [SettingsTabRoutingKeys] enum to get the actual route
/// path for an enum
extension SettingsTabRoutingKeysFunctions on SettingsTabRoutingKeys {
  String get route => {
        SettingsTabRoutingKeys.Landing: AppRoutingKeys.Tabs.route + '/settings',
        SettingsTabRoutingKeys.PrivacyPolicy:
            AppRoutingKeys.Tabs.route + '/settings/privacy-policy',
        SettingsTabRoutingKeys.About:
            AppRoutingKeys.Tabs.route + '/settings/about',
        SettingsTabRoutingKeys.CustomTheme:
            AppRoutingKeys.Tabs.route + '/settings/custom-theme',
        SettingsTabRoutingKeys.FAQ: AppRoutingKeys.Tabs.route + '/settings/faq',
        SettingsTabRoutingKeys.DataManagement:
            AppRoutingKeys.Tabs.route + '/settings/data-management',
        SettingsTabRoutingKeys.Logs:
            AppRoutingKeys.Tabs.route + '/settings/logs',
        SettingsTabRoutingKeys.LogDetail:
            AppRoutingKeys.Tabs.route + '/settings/logs/detail',
      }[this]!;
}

/// Used to summarize routing tasks and information at one point
class RoutingHelper {
  static Map<String, Widget Function(BuildContext)> homeTabRoutes = {
    HomeTabRoutingKeys.Landing.route: (_) => HomeView(),
    HomeTabRoutingKeys.Dashboard.route: (_) => DashboardView(),
  };

  static Map<String, Widget Function(BuildContext)> statisticsTabRoutes = {
    StaticticsTabRoutingKeys.Landing.route: (_) => StatisticsView(),
    StaticticsTabRoutingKeys.Detail.route: (_) => StatisticDetailView(),
  };

  static Map<String, Widget Function(BuildContext)> settingsTabRoutes = {
    SettingsTabRoutingKeys.Landing.route: (_) => SettingsView(),
    SettingsTabRoutingKeys.PrivacyPolicy.route: (_) => PrivacyPolicyView(),
    SettingsTabRoutingKeys.About.route: (_) => AboutView(),
    SettingsTabRoutingKeys.CustomTheme.route: (_) => CustomThemeView(),
    SettingsTabRoutingKeys.FAQ.route: (_) => FAQView(),
    SettingsTabRoutingKeys.DataManagement.route: (_) => DataManagementView(),
    SettingsTabRoutingKeys.Logs.route: (_) => LogsView(),
    SettingsTabRoutingKeys.LogDetail.route: (_) => LogDetailView(),
  };

  static Map<String, Widget Function(BuildContext)> appRoutes = {
    AppRoutingKeys.Intro.route: (_) => IntroView(),
    AppRoutingKeys.Tabs.route: (_) => TabBase(),
  };
}
