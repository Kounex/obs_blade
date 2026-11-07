// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_access.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$RemoteAccessStore on _RemoteAccessStore, Store {
  late final _$phaseAtom = Atom(
    name: '_RemoteAccessStore.phase',
    context: context,
  );

  @override
  RemotePairingPhase get phase {
    _$phaseAtom.reportRead();
    return super.phase;
  }

  @override
  set phase(RemotePairingPhase value) {
    _$phaseAtom.reportWrite(value, super.phase, () {
      super.phase = value;
    });
  }

  late final _$failureAtom = Atom(
    name: '_RemoteAccessStore.failure',
    context: context,
  );

  @override
  RemotePairingFailure? get failure {
    _$failureAtom.reportRead();
    return super.failure;
  }

  @override
  set failure(RemotePairingFailure? value) {
    _$failureAtom.reportWrite(value, super.failure, () {
      super.failure = value;
    });
  }

  late final _$codeAtom = Atom(
    name: '_RemoteAccessStore.code',
    context: context,
  );

  @override
  String? get code {
    _$codeAtom.reportRead();
    return super.code;
  }

  @override
  set code(String? value) {
    _$codeAtom.reportWrite(value, super.code, () {
      super.code = value;
    });
  }

  late final _$infoAtom = Atom(
    name: '_RemoteAccessStore.info',
    context: context,
  );

  @override
  RemoteBridgeInfo? get info {
    _$infoAtom.reportRead();
    return super.info;
  }

  @override
  set info(RemoteBridgeInfo? value) {
    _$infoAtom.reportWrite(value, super.info, () {
      super.info = value;
    });
  }

  late final _$infoLoadingAtom = Atom(
    name: '_RemoteAccessStore.infoLoading',
    context: context,
  );

  @override
  bool get infoLoading {
    _$infoLoadingAtom.reportRead();
    return super.infoLoading;
  }

  @override
  set infoLoading(bool value) {
    _$infoLoadingAtom.reportWrite(value, super.infoLoading, () {
      super.infoLoading = value;
    });
  }

  late final _$infoErrorAtom = Atom(
    name: '_RemoteAccessStore.infoError',
    context: context,
  );

  @override
  RemoteRelayException? get infoError {
    _$infoErrorAtom.reportRead();
    return super.infoError;
  }

  @override
  set infoError(RemoteRelayException? value) {
    _$infoErrorAtom.reportWrite(value, super.infoError, () {
      super.infoError = value;
    });
  }

  late final _$pairAsyncAction = AsyncAction(
    '_RemoteAccessStore.pair',
    context: context,
  );

  @override
  Future<void> pair(
    Connection connection, {
    required String deviceName,
    required String platform,
  }) {
    return _$pairAsyncAction.run(
      () => super.pair(connection, deviceName: deviceName, platform: platform),
    );
  }

  late final _$refreshAsyncAction = AsyncAction(
    '_RemoteAccessStore.refresh',
    context: context,
  );

  @override
  Future<void> refresh(Connection connection) {
    return _$refreshAsyncAction.run(() => super.refresh(connection));
  }

  late final _$removeDeviceAsyncAction = AsyncAction(
    '_RemoteAccessStore.removeDevice',
    context: context,
  );

  @override
  Future<bool> removeDevice(Connection connection, String deviceId) {
    return _$removeDeviceAsyncAction.run(
      () => super.removeDevice(connection, deviceId),
    );
  }

  late final _$_RemoteAccessStoreActionController = ActionController(
    name: '_RemoteAccessStore',
    context: context,
  );

  @override
  void cancel() {
    final _$actionInfo = _$_RemoteAccessStoreActionController.startAction(
      name: '_RemoteAccessStore.cancel',
    );
    try {
      return super.cancel();
    } finally {
      _$_RemoteAccessStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _fail(RemotePairingFailure failure) {
    final _$actionInfo = _$_RemoteAccessStoreActionController.startAction(
      name: '_RemoteAccessStore._fail',
    );
    try {
      return super._fail(failure);
    } finally {
      _$_RemoteAccessStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _forgetLocally(Connection connection) {
    final _$actionInfo = _$_RemoteAccessStoreActionController.startAction(
      name: '_RemoteAccessStore._forgetLocally',
    );
    try {
      return super._forgetLocally(connection);
    } finally {
      _$_RemoteAccessStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
phase: ${phase},
failure: ${failure},
code: ${code},
info: ${info},
infoLoading: ${infoLoading},
infoError: ${infoError}
    ''';
  }
}
