// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'landing.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$LandingStore on _LandingStore, Store {
  final _$_refreshableAtom = Atom(name: '_LandingStore._refreshable');

  @override
  bool get _refreshable {
    _$_refreshableAtom.context.enforceReadPolicy(_$_refreshableAtom);
    _$_refreshableAtom.reportObserved();
    return super._refreshable;
  }

  @override
  set _refreshable(bool value) {
    _$_refreshableAtom.context.conditionallyRunInAction(() {
      super._refreshable = value;
      _$_refreshableAtom.reportChanged();
    }, _$_refreshableAtom, name: '${_$_refreshableAtom.name}_set');
  }

  final _$_obsAutodiscoverConnectionsAtom =
      Atom(name: '_LandingStore._obsAutodiscoverConnections');

  @override
  Future<List<Connection>> get _obsAutodiscoverConnections {
    _$_obsAutodiscoverConnectionsAtom.context
        .enforceReadPolicy(_$_obsAutodiscoverConnectionsAtom);
    _$_obsAutodiscoverConnectionsAtom.reportObserved();
    return super._obsAutodiscoverConnections;
  }

  @override
  set _obsAutodiscoverConnections(Future<List<Connection>> value) {
    _$_obsAutodiscoverConnectionsAtom.context.conditionallyRunInAction(() {
      super._obsAutodiscoverConnections = value;
      _$_obsAutodiscoverConnectionsAtom.reportChanged();
    }, _$_obsAutodiscoverConnectionsAtom,
        name: '${_$_obsAutodiscoverConnectionsAtom.name}_set');
  }

  final _$_manualModeAtom = Atom(name: '_LandingStore._manualMode');

  @override
  bool get _manualMode {
    _$_manualModeAtom.context.enforceReadPolicy(_$_manualModeAtom);
    _$_manualModeAtom.reportObserved();
    return super._manualMode;
  }

  @override
  set _manualMode(bool value) {
    _$_manualModeAtom.context.conditionallyRunInAction(() {
      super._manualMode = value;
      _$_manualModeAtom.reportChanged();
    }, _$_manualModeAtom, name: '${_$_manualModeAtom.name}_set');
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
  void updateObsAutodiscoverConnections() {
    final _$actionInfo = _$_LandingStoreActionController.startAction();
    try {
      return super.updateObsAutodiscoverConnections();
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
    final string = '';
    return '{$string}';
  }
}
