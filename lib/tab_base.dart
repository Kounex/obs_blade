import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/utils/styling_helper.dart';

import 'stores/shared/tabs.dart';
import 'utils/routing_helper.dart';

class ActiveRouteObserver extends NavigatorObserver {
  final Tabs tab;

  ActiveRouteObserver({required this.tab});

  /// The [Navigator] pushed `route`.
  ///
  /// The route immediately below that one, and thus the previously active
  /// route, is `previousRoute`.
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name != null) {
      GetIt.instance<TabsStore>().activeRoutePerNavigator[tab] =
          route.settings.name!;
    }
  }

  /// The [Navigator] popped `route`.
  ///
  /// The route immediately below that one, and thus the newly active
  /// route, is `previousRoute`.
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null && previousRoute.settings.name != null) {
      GetIt.instance<TabsStore>().activeRoutePerNavigator[tab] =
          previousRoute.settings.name!;
    }
  }
}

class TabBase extends StatefulWidget {
  const TabBase({
    super.key,
  });

  @override
  _TabBaseState createState() => _TabBaseState();
}

class _TabBaseState extends State<TabBase> {
  final Map<Tabs, Navigator> _tabViews = {};
  final Map<Tabs, HeroController> _heroControllers = {};
  final Map<Tabs, ScrollController> _tabScrollController = {};

  Tween<Rect?> _createRectTween(Rect? begin, Rect? end) {
    return MaterialRectArcTween(begin: begin, end: end);
  }

  @override
  void initState() {
    super.initState();

    TabsStore tabsStore = GetIt.instance<TabsStore>();

    for (var tab in Tabs.values) {
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
          return CupertinoPageRoute(
            builder: tab.routes[routeSettings.name]!,
            settings: routeSettings,
          );
        },
        observers: [
          _heroControllers[tab]!,
          ActiveRouteObserver(tab: tab),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    TabsStore tabsStore = GetIt.instance<TabsStore>();

    return Scaffold(
      body: Observer(builder: (context) {
        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) {
            if (tabsStore.keyForCurrentTab().currentState!.canPop()) {
              tabsStore.keyForCurrentTab().currentState!.pop();
            } else if (tabsStore.activeTab != Tabs.Home) {
              tabsStore.setActiveTab(Tabs.Home);
            }
          },
          child: _TabSwitchTransition(
            activeTab: tabsStore.activeTab,
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
          ),
        );
      }),
      extendBody: true,
      bottomNavigationBar: Observer(
        builder: (context) => CupertinoTabBar(
          backgroundColor: !StylingHelper.isApple(context)
              ? CupertinoTheme.of(context).barBackgroundColor.withOpacity(1.0)
              : null,
          activeColor: Theme.of(context).colorScheme.secondary,
          currentIndex: tabsStore.activeTab.index,
          iconSize: 24.0,

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
                _tabScrollController[tappedTab]!.animateTo(
                  0.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeIn,
                );
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

/// "On Air" tab switch transition: 200ms fade + subtle scale of the tab
/// body whenever the active tab changes.
///
/// Implemented as a one-shot entrance animation around the persistent
/// [IndexedStack] rather than an [AnimatedSwitcher] keyed by tab: during a
/// switcher's crossfade both the outgoing and the incoming body would be
/// mounted at the same time, duplicating the per-tab [Navigator]
/// [GlobalKey]s (and tearing down every tab's navigation stack). This way
/// all tab navigators, their scroll positions and pushed routes stay fully
/// alive and untouched.
class _TabSwitchTransition extends StatefulWidget {
  final Tabs activeTab;
  final Widget child;

  const _TabSwitchTransition({
    required this.activeTab,
    required this.child,
  });

  @override
  State<_TabSwitchTransition> createState() => _TabSwitchTransitionState();
}

class _TabSwitchTransitionState extends State<_TabSwitchTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,

      /// Design system mandates 200ms for tab switches
      /// (`docs/redesign/design-system.md` - motion language)
      duration: const Duration(milliseconds: 200),
      value: 1.0,
    );
    CurvedAnimation curved = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.standard,
    );
    _opacity = curved;
    _scale = Tween<double>(begin: 0.98, end: 1.0).animate(curved);
  }

  @override
  void didUpdateWidget(covariant _TabSwitchTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeTab != widget.activeTab) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
