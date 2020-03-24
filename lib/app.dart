import 'package:flutter/material.dart';
import 'package:obs_station/utils/routing_helper.dart';
import 'package:obs_station/views/landing/landing.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      routes: RoutingHelper.routes,
      home: LandingView(),
    );
  }
}
