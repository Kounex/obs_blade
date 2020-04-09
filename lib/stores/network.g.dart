// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$NetworkStore on _NetworkStore, Store {
  final _$_autodiscoverConnectionsAtom =
      Atom(name: '_NetworkStore._autodiscoverConnections');

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

  final _$_autodiscoverPortAtom = Atom(name: '_NetworkStore._autodiscoverPort');

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

  final _$_obsWebSocketAtom = Atom(name: '_NetworkStore._obsWebSocket');

  @override
  IOWebSocketChannel get _obsWebSocket {
    _$_obsWebSocketAtom.context.enforceReadPolicy(_$_obsWebSocketAtom);
    _$_obsWebSocketAtom.reportObserved();
    return super._obsWebSocket;
  }

  @override
  set _obsWebSocket(IOWebSocketChannel value) {
    _$_obsWebSocketAtom.context.conditionallyRunInAction(() {
      super._obsWebSocket = value;
      _$_obsWebSocketAtom.reportChanged();
    }, _$_obsWebSocketAtom, name: '${_$_obsWebSocketAtom.name}_set');
  }

  final _$_connectionWasInProgressAtom =
      Atom(name: '_NetworkStore._connectionWasInProgress');

  @override
  bool get _connectionWasInProgress {
    _$_connectionWasInProgressAtom.context
        .enforceReadPolicy(_$_connectionWasInProgressAtom);
    _$_connectionWasInProgressAtom.reportObserved();
    return super._connectionWasInProgress;
  }

  @override
  set _connectionWasInProgress(bool value) {
    _$_connectionWasInProgressAtom.context.conditionallyRunInAction(() {
      super._connectionWasInProgress = value;
      _$_connectionWasInProgressAtom.reportChanged();
    }, _$_connectionWasInProgressAtom,
        name: '${_$_connectionWasInProgressAtom.name}_set');
  }

  final _$_connectionInProgressAtom =
      Atom(name: '_NetworkStore._connectionInProgress');

  @override
  bool get _connectionInProgress {
    _$_connectionInProgressAtom.context
        .enforceReadPolicy(_$_connectionInProgressAtom);
    _$_connectionInProgressAtom.reportObserved();
    return super._connectionInProgress;
  }

  @override
  set _connectionInProgress(bool value) {
    _$_connectionInProgressAtom.context.conditionallyRunInAction(() {
      super._connectionInProgress = value;
      _$_connectionInProgressAtom.reportChanged();
    }, _$_connectionInProgressAtom,
        name: '${_$_connectionInProgressAtom.name}_set');
  }

  final _$_connectedAtom = Atom(name: '_NetworkStore._connected');

  @override
  bool get _connected {
    _$_connectedAtom.context.enforceReadPolicy(_$_connectedAtom);
    _$_connectedAtom.reportObserved();
    return super._connected;
  }

  @override
  set _connected(bool value) {
    _$_connectedAtom.context.conditionallyRunInAction(() {
      super._connected = value;
      _$_connectedAtom.reportChanged();
    }, _$_connectedAtom, name: '${_$_connectedAtom.name}_set');
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
  String toString() {
    final string = '';
    return '{$string}';
  }
}
