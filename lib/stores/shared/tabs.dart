import 'dart:collection';

import 'package:mobx/mobx.dart';

part 'tabs.g.dart';

class TabsStore = _TabsStore with _$TabsStore;

abstract class _TabsStore with Store {
  @observable
  int tabIndex = 0;

  /// Might later be used as an indicator which says that the user tapped
  /// on a tab which is already active and in our views we can react to
  /// this (via MobX reaction) to do stuff like scroll up, open search etc.
  /// Right now not used since tapping on the current active tab will either
  /// pop the route if canPop() returns true or scroll up if its the root view
  /// of the tab and it attached the ScrollController (each tab gets a
  /// ScrollController as a navigation argument - used or not)
  @observable
  bool performTabClickAction = false;

  @action
  void setTabIndex(int tabIndex) => this.tabIndex = tabIndex;

  @action
  void setPerformTabClickAction(bool performTabClickAction) =>
      this.performTabClickAction = performTabClickAction;
}
