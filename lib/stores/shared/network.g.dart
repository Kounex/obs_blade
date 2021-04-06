// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$NetworkStore on _NetworkStore, Store {
  final _$activeSessionAtom = Atom(name: '_NetworkStore.activeSession');

  @override
  Session? get activeSession {
    _$activeSessionAtom.reportRead();
    return super.activeSession;
  }

  @override
  set activeSession(Session? value) {
    _$activeSessionAtom.reportWrite(value, super.activeSession, () {
      super.activeSession = value;
    });
  }

  final _$connectionInProgressAtom =
      Atom(name: '_NetworkStore.connectionInProgress');

  @override
  bool get connectionInProgress {
    _$connectionInProgressAtom.reportRead();
    return super.connectionInProgress;
  }

  @override
  set connectionInProgress(bool value) {
    _$connectionInProgressAtom.reportWrite(value, super.connectionInProgress,
        () {
      super.connectionInProgress = value;
    });
  }

  final _$connectionResponseAtom =
      Atom(name: '_NetworkStore.connectionResponse');

  @override
  BaseResponse? get connectionResponse {
    _$connectionResponseAtom.reportRead();
    return super.connectionResponse;
  }

  @override
  set connectionResponse(BaseResponse? value) {
    _$connectionResponseAtom.reportWrite(value, super.connectionResponse, () {
      super.connectionResponse = value;
    });
  }

  final _$obsTerminatedAtom = Atom(name: '_NetworkStore.obsTerminated');

  @override
  bool get obsTerminated {
    _$obsTerminatedAtom.reportRead();
    return super.obsTerminated;
  }

  @override
  set obsTerminated(bool value) {
    _$obsTerminatedAtom.reportWrite(value, super.obsTerminated, () {
      super.obsTerminated = value;
    });
  }

  final _$setOBSWebSocketAsyncAction =
      AsyncAction('_NetworkStore.setOBSWebSocket');

  @override
  Future<BaseResponse> setOBSWebSocket(Connection connection,
      {bool reconnect = false, Duration timeout = const Duration(seconds: 3)}) {
    return _$setOBSWebSocketAsyncAction.run(() => super
        .setOBSWebSocket(connection, reconnect: reconnect, timeout: timeout));
  }

  final _$_NetworkStoreActionController =
      ActionController(name: '_NetworkStore');

  @override
  void closeSession({bool manually = true}) {
    final _$actionInfo = _$_NetworkStoreActionController.startAction(
        name: '_NetworkStore.closeSession');
    try {
      return super.closeSession(manually: manually);
    } finally {
      _$_NetworkStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _handleEvent(BaseEvent event) {
    final _$actionInfo = _$_NetworkStoreActionController.startAction(
        name: '_NetworkStore._handleEvent');
    try {
      return super._handleEvent(event);
    } finally {
      _$_NetworkStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
activeSession: ${activeSession},
connectionInProgress: ${connectionInProgress},
connectionResponse: ${connectionResponse},
obsTerminated: ${obsTerminated}
    ''';
  }
}
