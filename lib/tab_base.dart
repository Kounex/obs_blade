import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_station/utils/routing_helper.dart';
import 'package:obs_station/types/extensions/list.dart';

class TabBase extends StatefulWidget {
  @override
  _TabBaseState createState() => _TabBaseState();
}

class _TabBaseState extends State<TabBase> {
  int _currentTabIndex = 0;

  List<Navigator> _tabViews;

  @override
  void initState() {
    _tabViews = [
      Navigator(
        key: GlobalKey(),
        initialRoute: HomeTabRoutingKeys.LANDING.route,
        onGenerateInitialRoutes: (state, route) => [
          CupertinoPageRoute(
            builder: RoutingHelper.homeTabRoutes[route],
          ),
        ],
        onGenerateRoute: (routeSettings) => CupertinoPageRoute(
          builder: RoutingHelper.homeTabRoutes[routeSettings.name],
          settings: routeSettings,
        ),
      ),
      Navigator(
        key: GlobalKey(),
        initialRoute: InfoTabRoutingKeys.LANDING.route,
        onGenerateInitialRoutes: (state, route) => [
          CupertinoPageRoute(
            builder: RoutingHelper.infoTabRoutes[route],
          ),
        ],
        onGenerateRoute: (routeSettings) => CupertinoPageRoute(
          builder: RoutingHelper.infoTabRoutes[routeSettings.name],
          settings: routeSettings,
        ),
      ),
      Navigator(
        key: GlobalKey(),
        initialRoute: SettingsTabRoutingKeys.LANDING.route,
        onGenerateInitialRoutes: (state, route) => [
          CupertinoPageRoute(
            builder: RoutingHelper.settingsTabRoutes[route],
          ),
        ],
        onGenerateRoute: (routeSettings) => CupertinoPageRoute(
          builder: RoutingHelper.settingsTabRoutes[routeSettings.name],
          settings: routeSettings,
        ),
      ),
    ];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: _tabViews
            .mapIndexed(
              (navigator, index) => Offstage(
                offstage: index != _currentTabIndex,
                child: navigator,
              ),
            )
            .toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) => setState(() {
          _currentTabIndex = index;
        }),
        items: [
          BottomNavigationBarItem(
            // backgroundColor:
            //     Theme.of(context).bottomNavigationBarTheme.backgroundColor,
            icon: Icon(CupertinoIcons.home),
            title: Text('Home'),
          ),
          BottomNavigationBarItem(
            // backgroundColor:
            //     Theme.of(context).bottomNavigationBarTheme.backgroundColor,
            icon: Icon(CupertinoIcons.info),
            title: Text('Info'),
          ),
          BottomNavigationBarItem(
            // backgroundColor:
            //     Theme.of(context).bottomNavigationBarTheme.backgroundColor,
            icon: Icon(CupertinoIcons.settings),
            title: Text('Settings'),
          ),
        ],
      ),
    );
  }
}
