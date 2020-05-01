import 'package:flutter/material.dart';
import 'package:obs_station/views/dashboard/dashboard.dart';
import 'package:obs_station/views/landing/landing.dart';

enum AppRoutingKeys { LANDING, DASHBOARD }

extension AppRoutingKeysFunctioins on AppRoutingKeys {
  String get route => const {
        AppRoutingKeys.LANDING: 'landing',
        AppRoutingKeys.DASHBOARD: 'dashboard',
      }[this];
}

class RoutingHelper {
  static Map<String, Widget Function(BuildContext)> routes = {
    AppRoutingKeys.LANDING.route: (_) => LandingView(),
    AppRoutingKeys.DASHBOARD.route: (_) => DashboardView()
  };
}
