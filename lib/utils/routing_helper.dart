import 'package:flutter/cupertino.dart';
import 'package:obs_blade/views/settings/dashboard_customisation/dashboard_customisation.dart';

import '../tab_base.dart';
import '../views/dashboard/dashboard.dart';
import '../views/home/home.dart';
import '../views/intro/intro.dart';
import '../views/settings/about/about.dart';
import '../views/settings/custom_theme/custom_theme.dart';
import '../views/settings/data_management/data_management.dart';
import '../views/settings/faq/faq.dart';
import '../views/settings/logs/log_detail/log_detail.dart';
import '../views/settings/logs/logs.dart';
import '../views/settings/privacy_policy/privacy_policy.dart';
import '../views/settings/settings.dart';
import '../views/statistics/statistic_detail/statistic_detail.dart';
import '../views/statistics/statistics.dart';

abstract class RoutingKeys {
  String get route;
}

/// All routing keys available on root level - for now the whole app
/// is wrapped in tabs and no other root level views (which are not inside
/// those tabs) are used
enum AppRoutingKeys implements RoutingKeys {
  Intro,
  Tabs;

  @override
  String get route => const {
        AppRoutingKeys.Intro: '/intro',
        AppRoutingKeys.Tabs: '/tabs',
      }[this]!;
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
enum HomeTabRoutingKeys implements RoutingKeys {
  Landing,
  Dashboard;

  @override
  String get route => '${AppRoutingKeys.Tabs.route}/home${{
        HomeTabRoutingKeys.Landing: '',
        HomeTabRoutingKeys.Dashboard: '/dashboard',
      }[this]!}';
}

/// Routing keys for the statistics tab
enum StaticticsTabRoutingKeys implements RoutingKeys {
  Landing,
  Detail;

  @override
  String get route => '${AppRoutingKeys.Tabs.route}/statistic${{
        StaticticsTabRoutingKeys.Landing: '',
        StaticticsTabRoutingKeys.Detail: '/detail',
      }[this]!}';
}

/// Routing keys for the settings tab
enum SettingsTabRoutingKeys implements RoutingKeys {
  Landing,
  PrivacyPolicy,
  About,
  CustomTheme,
  FAQ,
  DataManagement,
  Logs,
  LogDetail,
  DashboardCustomisation;

  @override
  String get route => '$AppRoutingKeys.Tabs.route/settings${{
        SettingsTabRoutingKeys.Landing: '',
        SettingsTabRoutingKeys.PrivacyPolicy: '/privacy-policy',
        SettingsTabRoutingKeys.About: '/about',
        SettingsTabRoutingKeys.CustomTheme: '/custom-theme',
        SettingsTabRoutingKeys.FAQ: '/faq',
        SettingsTabRoutingKeys.DataManagement: '/data-management',
        SettingsTabRoutingKeys.Logs: '/logs',
        SettingsTabRoutingKeys.LogDetail: '/logs/detail',
        SettingsTabRoutingKeys.DashboardCustomisation:
            '/dashboard-customisation',
      }[this]!}';
}

/// Used to summarize routing tasks and information at one point
class RoutingHelper {
  static Map<String, Widget Function(BuildContext)> homeTabRoutes = {
    HomeTabRoutingKeys.Landing.route: (_) => const HomeView(),
    HomeTabRoutingKeys.Dashboard.route: (_) => const DashboardView(),
  };

  static Map<String, Widget Function(BuildContext)> statisticsTabRoutes = {
    StaticticsTabRoutingKeys.Landing.route: (_) => const StatisticsView(),
    StaticticsTabRoutingKeys.Detail.route: (_) => const StatisticDetailView(),
  };

  static Map<String, Widget Function(BuildContext)> settingsTabRoutes = {
    SettingsTabRoutingKeys.Landing.route: (_) => const SettingsView(),
    SettingsTabRoutingKeys.PrivacyPolicy.route: (_) =>
        const PrivacyPolicyView(),
    SettingsTabRoutingKeys.About.route: (_) => const AboutView(),
    SettingsTabRoutingKeys.CustomTheme.route: (_) => const CustomThemeView(),
    SettingsTabRoutingKeys.FAQ.route: (_) => const FAQView(),
    SettingsTabRoutingKeys.DataManagement.route: (_) =>
        const DataManagementView(),
    SettingsTabRoutingKeys.Logs.route: (_) => const LogsView(),
    SettingsTabRoutingKeys.LogDetail.route: (_) => const LogDetailView(),
    SettingsTabRoutingKeys.DashboardCustomisation.route: (_) =>
        const DashboardCustomisationView(),
  };

  static Map<String, Widget Function(BuildContext)> appRoutes = {
    AppRoutingKeys.Intro.route: (_) => const IntroView(),
    AppRoutingKeys.Tabs.route: (_) => const TabBase(),
  };
}
