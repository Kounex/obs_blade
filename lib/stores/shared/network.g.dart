// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$NetworkStore on _NetworkStore, Store {
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

  final _$connectionResponseAtom =
      Atom(name: '_NetworkStore.connectionResponse');

  @override
  BaseResponse get connectionResponse {
    _$connectionResponseAtom.context
        .enforceReadPolicy(_$connectionResponseAtom);
    _$connectionResponseAtom.reportObserved();
    return super.connectionResponse;
  }

  @override
  set connectionResponse(BaseResponse value) {
    _$connectionResponseAtom.context.conditionallyRunInAction(() {
      super.connectionResponse = value;
      _$connectionResponseAtom.reportChanged();
    }, _$connectionResponseAtom, name: '${_$connectionResponseAtom.name}_set');
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
  Future<BaseResponse> setOBSWebSocket(Connection connection,
      {Duration timeout = const Duration(seconds: 3)}) {
    return _$setOBSWebSocketAsyncAction
        .run(() => super.setOBSWebSocket(connection, timeout: timeout));
  }

  final _$_NetworkStoreActionController =
      ActionController(name: '_NetworkStore');

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
        'activeSession: ${activeSession.toString()},connectionResponse: ${connectionResponse.toString()},connectionWasInProgress: ${connectionWasInProgress.toString()},connectionInProgress: ${connectionInProgress.toString()}';
    return '{$string}';
  }
}
