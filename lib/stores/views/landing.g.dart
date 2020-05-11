// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'landing.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$LandingStore on _LandingStore, Store {
  final _$autodiscoverConnectionsAtom =
      Atom(name: '_LandingStore.autodiscoverConnections');

  @override
  Future<List<Connection>> get autodiscoverConnections {
    _$autodiscoverConnectionsAtom.context
        .enforceReadPolicy(_$autodiscoverConnectionsAtom);
    _$autodiscoverConnectionsAtom.reportObserved();
    return super.autodiscoverConnections;
  }

  @override
  set autodiscoverConnections(Future<List<Connection>> value) {
    _$autodiscoverConnectionsAtom.context.conditionallyRunInAction(() {
      super.autodiscoverConnections = value;
      _$autodiscoverConnectionsAtom.reportChanged();
    }, _$autodiscoverConnectionsAtom,
        name: '${_$autodiscoverConnectionsAtom.name}_set');
  }

  final _$autodiscoverPortAtom = Atom(name: '_LandingStore.autodiscoverPort');

  @override
  String get autodiscoverPort {
    _$autodiscoverPortAtom.context.enforceReadPolicy(_$autodiscoverPortAtom);
    _$autodiscoverPortAtom.reportObserved();
    return super.autodiscoverPort;
  }

  @override
  set autodiscoverPort(String value) {
    _$autodiscoverPortAtom.context.conditionallyRunInAction(() {
      super.autodiscoverPort = value;
      _$autodiscoverPortAtom.reportChanged();
    }, _$autodiscoverPortAtom, name: '${_$autodiscoverPortAtom.name}_set');
  }

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

  final _$isCoolAtom = Atom(name: '_LandingStore.isCool');

  @override
  bool get isCool {
    _$isCoolAtom.context.enforceReadPolicy(_$isCoolAtom);
    _$isCoolAtom.reportObserved();
    return super.isCool;
  }

  @override
  set isCool(bool value) {
    _$isCoolAtom.context.conditionallyRunInAction(() {
      super.isCool = value;
      _$isCoolAtom.reportChanged();
    }, _$isCoolAtom, name: '${_$isCoolAtom.name}_set');
  }

  final _$_LandingStoreActionController =
      ActionController(name: '_LandingStore');

  @override
  void toggleIsCool() {
    final _$actionInfo = _$_LandingStoreActionController.startAction();
    try {
      return super.toggleIsCool();
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
        'autodiscoverConnections: ${autodiscoverConnections.toString()},autodiscoverPort: ${autodiscoverPort.toString()},refreshable: ${refreshable.toString()},manualMode: ${manualMode.toString()},isCool: ${isCool.toString()}';
    return '{$string}';
  }
}
