// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'landing.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$LandingStore on _LandingStore, Store {
  final _$refreshableAtom = Atom(name: '_LandingStore.refreshable');

  @override
  bool get refreshable {
    _$refreshableAtom.context.enforceReadPolicy(_$refreshableAtom);
    _$refreshableAtom.reportObserved();
    return super.refreshable;
  }

  @override
  set refreshable(bool value) {
    _$refreshableAtom.context.conditionallyRunInAction(() {
      super.refreshable = value;
      _$refreshableAtom.reportChanged();
    }, _$refreshableAtom, name: '${_$refreshableAtom.name}_set');
  }

  final _$manualModeAtom = Atom(name: '_LandingStore.manualMode');

  @override
  bool get manualMode {
    _$manualModeAtom.context.enforceReadPolicy(_$manualModeAtom);
    _$manualModeAtom.reportObserved();
    return super.manualMode;
  }

  @override
  set manualMode(bool value) {
    _$manualModeAtom.context.conditionallyRunInAction(() {
      super.manualMode = value;
      _$manualModeAtom.reportChanged();
    }, _$manualModeAtom, name: '${_$manualModeAtom.name}_set');
  }

  final _$_LandingStoreActionController =
      ActionController(name: '_LandingStore');

  @override
  void setRefreshable(bool refreshable) {
    final _$actionInfo = _$_LandingStoreActionController.startAction();
    try {
      return super.setRefreshable(refreshable);
    } finally {
      _$_LandingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleManualMode([bool manualMode]) {
    final _$actionInfo = _$_LandingStoreActionController.startAction();
    try {
      return super.toggleManualMode(manualMode);
    } finally {
      _$_LandingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    final string =
        'refreshable: ${refreshable.toString()},manualMode: ${manualMode.toString()}';
    return '{$string}';
  }
}
