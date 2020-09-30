import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:obs_blade/stores/shared/tabs.dart';
import 'package:provider/provider.dart';
import './types/extensions/list.dart';

import 'types/extensions/list.dart';
import 'utils/routing_helper.dart';

class TabBase extends StatefulWidget {
  @override
  _TabBaseState createState() => _TabBaseState();
}

class _TabBaseState extends State<TabBase> {
  List<Navigator> _tabViews;
  List<GlobalKey<NavigatorState>> _navigatorKeys = [];
  List<HeroController> _heroControllers = [];
  List<ScrollController> _tabScrollController = [];

  RectTween _createRectTween(Rect begin, Rect end) {
    return MaterialRectArcTween(begin: begin, end: end);
  }

  @override
  void initState() {
    super.initState();
    Tabs.values.forEach((tab) {
      _navigatorKeys.add(
        GlobalKey<NavigatorState>(debugLabel: tab.name),
      );
      _heroControllers.add(
        HeroController(createRectTween: _createRectTween),
      );
      _tabScrollController.add(
        ScrollController(),
      );
    });
    _tabViews = Tabs.values
        .mapIndexed(
          (tab, index) => Navigator(
            key: _navigatorKeys[index],
            initialRoute: tab.routes.keys.first,
            onGenerateInitialRoutes: (state, route) => [
              CupertinoPageRoute(
                builder: tab.routes[route],
                settings: RouteSettings(
                  name: route,
                  arguments: _tabScrollController[index],
                ),
              ),
            ],
            onGenerateRoute: (routeSettings) => CupertinoPageRoute(
              builder: tab.routes[routeSettings.name],
              settings: routeSettings,
            ),
            observers: [_heroControllers[index]],
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    TabsStore tabsStore = context.watch<TabsStore>();

    return Scaffold(
      body: Observer(builder: (_) {
        return IndexedStack(
          index: tabsStore.tabIndex,
          children: _tabViews
              .mapIndexed(
                (navigator, index) => Offstage(
                  offstage: index != tabsStore.tabIndex,
                  child: navigator,
                ),
              )
              .toList(),
        );
      }),
      bottomNavigationBar: Observer(
        builder: (_) => CupertinoTabBar(
          activeColor: Theme.of(context).accentColor,
          currentIndex: tabsStore.tabIndex,
          onTap: (index) {
            if (tabsStore.tabIndex == index) {
              tabsStore.setPerformTabClickAction(true);
              if (_navigatorKeys[index].currentState.canPop()) {
                _navigatorKeys[index].currentState.pop();
              } else if (_tabScrollController[index].hasClients &&
                  _tabScrollController[index].offset > 0) {
                _tabScrollController[index].animateTo(0.0,
                    duration: Duration(milliseconds: 250),
                    curve: Curves.easeIn);
              }
            } else {
              tabsStore.setTabIndex(index);
            }
          },
          items: Tabs.values
              .map(
                (tab) => BottomNavigationBarItem(
                  icon: Icon(tab.icon),
                  label: tab.name,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
