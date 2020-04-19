// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$NetworkStore on _NetworkStore, Store {
  final _$autodiscoverConnectionsAtom =
      Atom(name: '_NetworkStore.autodiscoverConnections');

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

  final _$autodiscoverPortAtom = Atom(name: '_NetworkStore.autodiscoverPort');

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

  final _$activeSessionAtom = Atom(name: '_NetworkStore.activeSession');

  @override
  Session get activeSession {
    _$activeSessionAtom.context.enforceReadPolicy(_$activeSessionAtom);
    _$activeSessionAtom.reportObserved();
    return super.activeSession;
  }

  @override
  set activeSession(Session value) {
    _$activeSessionAtom.context.conditionallyRunInAction(() {
      super.activeSession = value;
      _$activeSessionAtom.reportChanged();
    }, _$activeSessionAtom, name: '${_$activeSessionAtom.name}_set');
  }

  final _$connectedAtom = Atom(name: '_NetworkStore.connected');

  @override
  bool get connected {
    _$connectedAtom.context.enforceReadPolicy(_$connectedAtom);
    _$connectedAtom.reportObserved();
    return super.connected;
  }

  @override
  set connected(bool value) {
    _$connectedAtom.context.conditionallyRunInAction(() {
      super.connected = value;
      _$connectedAtom.reportChanged();
    }, _$connectedAtom, name: '${_$connectedAtom.name}_set');
  }

  final _$connectionWasInProgressAtom =
      Atom(name: '_NetworkStore.connectionWasInProgress');

  @override
  bool get connectionWasInProgress {
    _$connectionWasInProgressAtom.context
        .enforceReadPolicy(_$connectionWasInProgressAtom);
    _$connectionWasInProgressAtom.reportObserved();
    return super.connectionWasInProgress;
  }

  @override
  set connectionWasInProgress(bool value) {
    _$connectionWasInProgressAtom.context.conditionallyRunInAction(() {
      super.connectionWasInProgress = value;
      _$connectionWasInProgressAtom.reportChanged();
    }, _$connectionWasInProgressAtom,
        name: '${_$connectionWasInProgressAtom.name}_set');
  }

  final _$connectionInProgressAtom =
      Atom(name: '_NetworkStore.connectionInProgress');

  @override
  bool get connectionInProgress {
    _$connectionInProgressAtom.context
        .enforceReadPolicy(_$connectionInProgressAtom);
    _$connectionInProgressAtom.reportObserved();
    return super.connectionInProgress;
  }

  @override
  set connectionInProgress(bool value) {
    _$connectionInProgressAtom.context.conditionallyRunInAction(() {
      super.connectionInProgress = value;
      _$connectionInProgressAtom.reportChanged();
    }, _$connectionInProgressAtom,
        name: '${_$connectionInProgressAtom.name}_set');
  }

  final _$setOBSWebSocketAsyncAction = AsyncAction('setOBSWebSocket');

  @override
  Future<void> setOBSWebSocket(Connection connection,
      {Duration timeout = const Duration(seconds: 3)}) {
    return _$setOBSWebSocketAsyncAction
        .run(() => super.setOBSWebSocket(connection, timeout: timeout));
  }

  final _$_NetworkStoreActionController =
      ActionController(name: '_NetworkStore');

  @override
  void setAutodiscoverPort(String autodiscoverPort) {
    final _$actionInfo = _$_NetworkStoreActionController.startAction();
    try {
      return super.setAutodiscoverPort(autodiscoverPort);
    } finally {
      _$_NetworkStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateAutodiscoverConnections() {
    final _$actionInfo = _$_NetworkStoreActionController.startAction();
    try {
      return super.updateAutodiscoverConnections();
    } finally {
      _$_NetworkStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void closeSession() {
    final _$actionInfo = _$_NetworkStoreActionController.startAction();
    try {
      return super.closeSession();
    } finally {
      _$_NetworkStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    final string =
        'autodiscoverConnections: ${autodiscoverConnections.toString()},autodiscoverPort: ${autodiscoverPort.toString()},activeSession: ${activeSession.toString()},connected: ${connected.toString()},connectionWasInProgress: ${connectionWasInProgress.toString()},connectionInProgress: ${connectionInProgress.toString()}';
    return '{$string}';
  }
}
