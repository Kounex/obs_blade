import 'package:flutter/material.dart';
import 'package:obs_station/views/landing/landing.dart';

class RoutingHelper {
  static const String landing = 'landing';

  static Map<String, Widget Function(BuildContext)> routes = {
    landing: (_) => LandingView()
  };
}
