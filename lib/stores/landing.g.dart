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

  final _$_autodiscoverConnectionsAtom =
      Atom(name: '_LandingStore._autodiscoverConnections');

  @override
  Future<List<Connection>> get _autodiscoverConnections {
    _$_autodiscoverConnectionsAtom.context
        .enforceReadPolicy(_$_autodiscoverConnectionsAtom);
    _$_autodiscoverConnectionsAtom.reportObserved();
    return super._autodiscoverConnections;
  }

  @override
  set _autodiscoverConnections(Future<List<Connection>> value) {
    _$_autodiscoverConnectionsAtom.context.conditionallyRunInAction(() {
      super._autodiscoverConnections = value;
      _$_autodiscoverConnectionsAtom.reportChanged();
    }, _$_autodiscoverConnectionsAtom,
        name: '${_$_autodiscoverConnectionsAtom.name}_set');
  }

  final _$_autodiscoverPortAtom = Atom(name: '_LandingStore._autodiscoverPort');

  @override
  String get _autodiscoverPort {
    _$_autodiscoverPortAtom.context.enforceReadPolicy(_$_autodiscoverPortAtom);
    _$_autodiscoverPortAtom.reportObserved();
    return super._autodiscoverPort;
  }

  @override
  set _autodiscoverPort(String value) {
    _$_autodiscoverPortAtom.context.conditionallyRunInAction(() {
      super._autodiscoverPort = value;
      _$_autodiscoverPortAtom.reportChanged();
    }, _$_autodiscoverPortAtom, name: '${_$_autodiscoverPortAtom.name}_set');
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
  void setAutodiscoverPort(String autodiscoverPort) {
    final _$actionInfo = _$_LandingStoreActionController.startAction();
    try {
      return super.setAutodiscoverPort(autodiscoverPort);
    } finally {
      _$_LandingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateAutodiscoverConnections() {
    final _$actionInfo = _$_LandingStoreActionController.startAction();
    try {
      return super.updateAutodiscoverConnections();
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
