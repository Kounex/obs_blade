import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import 'stores/shared/tabs.dart';
import 'utils/routing_helper.dart';

class TabBase extends StatefulWidget {
  @override
  _TabBaseState createState() => _TabBaseState();
}

class _TabBaseState extends State<TabBase> {
  Map<Tabs, Navigator> _tabViews = {};
  Map<Tabs, HeroController> _heroControllers = {};
  Map<Tabs, ScrollController> _tabScrollController = {};

  Tween<Rect?> _createRectTween(Rect? begin, Rect? end) {
    return MaterialRectArcTween(begin: begin, end: end);
  }

  @override
  void initState() {
    super.initState();

    TabsStore tabsStore = GetIt.instance<TabsStore>();

    Tabs.values.forEach((tab) {
      tabsStore.navigatorKeys[tab] =
          GlobalKey<NavigatorState>(debugLabel: tab.name);
      _heroControllers[tab] = HeroController(createRectTween: _createRectTween);
      _tabScrollController[tab] = ScrollController();

      _tabViews[tab] = Navigator(
        key: tabsStore.navigatorKeys[tab],
        initialRoute: tab.routes.keys.first,
        onGenerateInitialRoutes: (state, route) {
          tabsStore.activeRoutePerNavigator[tab] = route;
          return [
            CupertinoPageRoute(
              builder: tab.routes[route]!,
              settings: RouteSettings(
                name: route,
                arguments: _tabScrollController[tab],
              ),
            ),
          ];
        },
        onGenerateRoute: (routeSettings) {
          tabsStore.activeRoutePerNavigator[tab] = routeSettings.name!;
          return CupertinoPageRoute(
            builder: tab.routes[routeSettings.name]!,
            settings: routeSettings,
          );
        },
        observers: [_heroControllers[tab]!],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    TabsStore tabsStore = GetIt.instance<TabsStore>();

    return Scaffold(
      body: Observer(builder: (_) {
        return WillPopScope(
          onWillPop: () {
            if (tabsStore.navigatorKeys[tabsStore.activeTab]!.currentState!
                .canPop()) {
              tabsStore.navigatorKeys[tabsStore.activeTab]!.currentState!.pop();
              return Future.value(false);
            } else if (tabsStore.activeTab != Tabs.Home) {
              tabsStore.setActiveTab(Tabs.Home);
              return Future.value(false);
            }
            return Future.value(true);
          },
          child: IndexedStack(
            index: tabsStore.activeTab.index,
            children: _tabViews
                .map(
                  (tab, tabView) => MapEntry(
                    tab,
                    Offstage(
                      offstage: tab != tabsStore.activeTab,
                      child: tabView,
                    ),
                  ),
                )
                .values
                .toList(),
          ),
        );
      }),
      bottomNavigationBar: Observer(
        builder: (_) => CupertinoTabBar(
          activeColor: Theme.of(context).accentColor,
          currentIndex: tabsStore.activeTab.index,

          /// Used the standard implementation for [border] as seen
          /// in [CupertinoTabBar] but adjusted the [darkColor] property
          /// from 0x29000000 to 0x29FFFFFF (remain opacity but actually
          /// make the border visible on dark themes)
          border: const Border(
            top: BorderSide(
              color: CupertinoDynamicColor.withBrightness(
                color: Color(0x4C000000),
                darkColor: Color(0x29FFFFFF),
              ),
              width: 0.0,
              style: BorderStyle.solid,
            ),
          ),
          onTap: (index) {
            Tabs tappedTab = Tabs.values[index];
            if (tabsStore.activeTab == tappedTab) {
              tabsStore.setPerformTabClickAction(true);
              if (tabsStore.navigatorKeys[tappedTab]!.currentState!.canPop()) {
                tabsStore.navigatorKeys[tappedTab]!.currentState!.pop();
              } else if (_tabScrollController[tappedTab]!.hasClients &&
                  _tabScrollController[tappedTab]!.offset > 0) {
                _tabScrollController[tappedTab]!.animateTo(0.0,
                    duration: Duration(milliseconds: 250),
                    curve: Curves.easeIn);
              }
            } else {
              tabsStore.setActiveTab(Tabs.values[index]);
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
