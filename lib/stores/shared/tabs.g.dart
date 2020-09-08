// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tabs.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$TabsStore on _TabsStore, Store {
  final _$tabIndexAtom = Atom(name: '_TabsStore.tabIndex');

  @override
  int get tabIndex {
    _$tabIndexAtom.reportRead();
    return super.tabIndex;
  }

  @override
  set tabIndex(int value) {
    _$tabIndexAtom.reportWrite(value, super.tabIndex, () {
      super.tabIndex = value;
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
  void setTabIndex(int tabIndex) {
    final _$actionInfo = _$_TabsStoreActionController.startAction(
        name: '_TabsStore.setTabIndex');
    try {
      return super.setTabIndex(tabIndex);
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
tabIndex: ${tabIndex},
performTabClickAction: ${performTabClickAction}
    ''';
  }
}
