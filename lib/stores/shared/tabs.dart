import 'dart:collection';

import 'package:mobx/mobx.dart';

part 'tabs.g.dart';

class TabsStore = _TabsStore with _$TabsStore;

abstract class _TabsStore with Store {
  @observable
  int tabIndex = 0;

  @observable
  bool performTabClickAction = false;

  @action
  void setTabIndex(int tabIndex) => this.tabIndex = tabIndex;

  @action
  void setPerformTabClickAction(bool performTabClickAction) =>
      this.performTabClickAction = performTabClickAction;
}
