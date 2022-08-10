// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$NetworkStore on _NetworkStore, Store {
  late final _$activeSessionAtom =
      Atom(name: '_NetworkStore.activeSession', context: context);

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

  late final _$connectionInProgressAtom =
      Atom(name: '_NetworkStore.connectionInProgress', context: context);

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

  late final _$connectionClodeCodeAtom =
      Atom(name: '_NetworkStore.connectionClodeCode', context: context);

  @override
  WebSocketCloseCode? get connectionClodeCode {
    _$connectionClodeCodeAtom.reportRead();
    return super.connectionClodeCode;
  }

  @override
  set connectionClodeCode(WebSocketCloseCode? value) {
    _$connectionClodeCodeAtom.reportWrite(value, super.connectionClodeCode, () {
      super.connectionClodeCode = value;
    });
  }

  late final _$obsTerminatedAtom =
      Atom(name: '_NetworkStore.obsTerminated', context: context);

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

  late final _$setOBSWebSocketAsyncAction =
      AsyncAction('_NetworkStore.setOBSWebSocket', context: context);

  @override
  Future<WebSocketCloseCode> setOBSWebSocket(Connection connection,
      {bool reconnect = false, Duration timeout = const Duration(seconds: 3)}) {
    return _$setOBSWebSocketAsyncAction.run(() => super
        .setOBSWebSocket(connection, reconnect: reconnect, timeout: timeout));
  }

  late final _$_NetworkStoreActionController =
      ActionController(name: '_NetworkStore', context: context);

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
connectionClodeCode: ${connectionClodeCode},
obsTerminated: ${obsTerminated}
    ''';
  }
}
