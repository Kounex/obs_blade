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
  List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  void initState() {
    _tabViews = [
      Navigator(
        key: _navigatorKeys[0],
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
        key: _navigatorKeys[1],
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
          if (_currentTabIndex == index) {
            if (_navigatorKeys[index].currentState.canPop()) {
              _navigatorKeys[index].currentState.pop();
            }
          } else {
            _currentTabIndex = index;
          }
        }),
        items: [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            title: Text('Home'),
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            title: Text('Settings'),
          ),
        ],
      ),
    );
  }
}
