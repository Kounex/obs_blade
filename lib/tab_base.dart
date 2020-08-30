import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'types/extensions/list.dart';
import 'utils/routing_helper.dart';
import 'utils/styling_helper.dart';

class TabBase extends StatefulWidget {
  @override
  _TabBaseState createState() => _TabBaseState();
}

class _TabBaseState extends State<TabBase> {
  int _currentTabIndex = 0;

  List<Navigator> _tabViews;
  List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(debugLabel: 'home'),
    GlobalKey<NavigatorState>(debugLabel: 'statistics'),
    GlobalKey<NavigatorState>(debugLabel: 'settings'),
  ];
  List<HeroController> _heroControllers;

  List<ScrollController> _tabScrollController;

  RectTween _createRectTween(Rect begin, Rect end) {
    return MaterialRectArcTween(begin: begin, end: end);
  }

  @override
  void initState() {
    super.initState();
    _heroControllers = [
      HeroController(createRectTween: _createRectTween),
      HeroController(createRectTween: _createRectTween),
      HeroController(createRectTween: _createRectTween)
    ];
    _tabScrollController = [
      ScrollController(),
      ScrollController(),
      ScrollController()
    ];
    _tabViews = [
      Navigator(
        key: _navigatorKeys[0],
        initialRoute: HomeTabRoutingKeys.Landing.route,
        onGenerateInitialRoutes: (state, route) => [
          CupertinoPageRoute(
            builder: RoutingHelper.homeTabRoutes[route],
            settings:
                RouteSettings(name: route, arguments: _tabScrollController[0]),
          ),
        ],
        onGenerateRoute: (routeSettings) => CupertinoPageRoute(
          builder: RoutingHelper.homeTabRoutes[routeSettings.name],
          settings: routeSettings,
        ),
        observers: [_heroControllers[0]],
      ),
      Navigator(
        key: _navigatorKeys[1],
        initialRoute: StaticticsTabRoutingKeys.Landing.route,
        onGenerateInitialRoutes: (state, route) => [
          CupertinoPageRoute(
            builder: RoutingHelper.statisticsTabRoutes[route],
            settings:
                RouteSettings(name: route, arguments: _tabScrollController[1]),
          ),
        ],
        onGenerateRoute: (routeSettings) => CupertinoPageRoute(
          builder: RoutingHelper.statisticsTabRoutes[routeSettings.name],
          settings: routeSettings,
        ),
        observers: [_heroControllers[1]],
      ),
      Navigator(
        key: _navigatorKeys[2],
        initialRoute: SettingsTabRoutingKeys.Landing.route,
        onGenerateInitialRoutes: (state, route) => [
          CupertinoPageRoute(
            builder: RoutingHelper.settingsTabRoutes[route],
            settings:
                RouteSettings(name: route, arguments: _tabScrollController[2]),
          ),
        ],
        onGenerateRoute: (routeSettings) => CupertinoPageRoute(
          builder: RoutingHelper.settingsTabRoutes[routeSettings.name],
          settings: routeSettings,
        ),
        observers: [_heroControllers[2]],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // body: Stack(
      //   children: _tabViews
      //       .mapIndexed(
      //         (navigator, index) => Offstage(
      //           offstage: index != _currentTabIndex,
      //           child: navigator,
      //         ),
      //       )
      //       .toList(),
      // ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: _tabViews
            .mapIndexed(
              (navigator, index) => Offstage(
                offstage: index != _currentTabIndex,
                child: navigator,
              ),
            )
            .toList(),
      ),

      bottomNavigationBar: CupertinoTabBar(
        currentIndex: _currentTabIndex,
        onTap: (index) => setState(() {
          if (_currentTabIndex == index) {
            if (_navigatorKeys[index].currentState.canPop()) {
              _navigatorKeys[index].currentState.pop();
            } else {
              _tabScrollController[index].animateTo(0.0,
                  duration: Duration(milliseconds: 250), curve: Curves.easeIn);
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
            icon: Icon(StylingHelper.CUPERTINO_BAR_ICON),
            title: Text('Statistics'),
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
