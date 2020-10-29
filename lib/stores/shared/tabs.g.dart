// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tabs.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$TabsStore on _TabsStore, Store {
  final _$activeTabAtom = Atom(name: '_TabsStore.activeTab');

  @override
  Tabs get activeTab {
    _$activeTabAtom.reportRead();
    return super.activeTab;
  }

  @override
  set activeTab(Tabs value) {
    _$activeTabAtom.reportWrite(value, super.activeTab, () {
      super.activeTab = value;
    });
  }

  final _$performTabClickActionAtom =
      Atom(name: '_TabsStore.performTabClickAction');

  @override
  bool get performTabClickAction {
    _$performTabClickActionAtom.reportRead();
    return super.performTabClickAction;
  }

  @override
  set performTabClickAction(bool value) {
    _$performTabClickActionAtom.reportWrite(value, super.performTabClickAction,
        () {
      super.performTabClickAction = value;
    });
  }

  final _$_TabsStoreActionController = ActionController(name: '_TabsStore');

  @override
  void setActiveTab(Tabs activeTab) {
    final _$actionInfo = _$_TabsStoreActionController.startAction(
        name: '_TabsStore.setActiveTab');
    try {
      return super.setActiveTab(activeTab);
    } finally {
      _$_TabsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setPerformTabClickAction(bool performTabClickAction) {
    final _$actionInfo = _$_TabsStoreActionController.startAction(
        name: '_TabsStore.setPerformTabClickAction');
    try {
      return super.setPerformTabClickAction(performTabClickAction);
    } finally {
      _$_TabsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
activeTab: ${activeTab},
performTabClickAction: ${performTabClickAction}
    ''';
  }
}
