// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$HomeStore on _HomeStore, Store {
  final _$autodiscoverConnectionsAtom =
      Atom(name: '_HomeStore.autodiscoverConnections');

  @override
  Future<List<Connection>>? get autodiscoverConnections {
    _$autodiscoverConnectionsAtom.reportRead();
    return super.autodiscoverConnections;
  }

  @override
  set autodiscoverConnections(Future<List<Connection>>? value) {
    _$autodiscoverConnectionsAtom
        .reportWrite(value, super.autodiscoverConnections, () {
      super.autodiscoverConnections = value;
    });
  }

  final _$autodiscoverPortAtom = Atom(name: '_HomeStore.autodiscoverPort');

  @override
  String get autodiscoverPort {
    _$autodiscoverPortAtom.reportRead();
    return super.autodiscoverPort;
  }

  @override
  set autodiscoverPort(String value) {
    _$autodiscoverPortAtom.reportWrite(value, super.autodiscoverPort, () {
      super.autodiscoverPort = value;
    });
  }

  final _$refreshableAtom = Atom(name: '_HomeStore.refreshable');

  @override
  bool get refreshable {
    _$refreshableAtom.reportRead();
    return super.refreshable;
  }

  @override
  set refreshable(bool value) {
    _$refreshableAtom.reportWrite(value, super.refreshable, () {
      super.refreshable = value;
    });
  }

  final _$manualModeAtom = Atom(name: '_HomeStore.manualMode');

  @override
  bool get manualMode {
    _$manualModeAtom.reportRead();
    return super.manualMode;
  }

  @override
  set manualMode(bool value) {
    _$manualModeAtom.reportWrite(value, super.manualMode, () {
      super.manualMode = value;
    });
  }

  final _$domainModeAtom = Atom(name: '_HomeStore.domainMode');

  @override
  bool get domainMode {
    _$domainModeAtom.reportRead();
    return super.domainMode;
  }

  @override
  set domainMode(bool value) {
    _$domainModeAtom.reportWrite(value, super.domainMode, () {
      super.domainMode = value;
    });
  }

  final _$_HomeStoreActionController = ActionController(name: '_HomeStore');

  @override
  void setAutodiscoverPort(String autodiscoverPort) {
    final _$actionInfo = _$_HomeStoreActionController.startAction(
        name: '_HomeStore.setAutodiscoverPort');
    try {
      return super.setAutodiscoverPort(autodiscoverPort);
    } finally {
      _$_HomeStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateAutodiscoverConnections() {
    final _$actionInfo = _$_HomeStoreActionController.startAction(
        name: '_HomeStore.updateAutodiscoverConnections');
    try {
      return super.updateAutodiscoverConnections();
    } finally {
      _$_HomeStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setRefreshable(bool refreshable) {
    final _$actionInfo = _$_HomeStoreActionController.startAction(
        name: '_HomeStore.setRefreshable');
    try {
      return super.setRefreshable(refreshable);
    } finally {
      _$_HomeStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setDomainMode(bool domainMode) {
    final _$actionInfo = _$_HomeStoreActionController.startAction(
        name: '_HomeStore.setDomainMode');
    try {
      return super.setDomainMode(domainMode);
    } finally {
      _$_HomeStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleManualMode([bool? manualMode]) {
    final _$actionInfo = _$_HomeStoreActionController.startAction(
        name: '_HomeStore.toggleManualMode');
    try {
      return super.toggleManualMode(manualMode);
    } finally {
      _$_HomeStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
autodiscoverConnections: ${autodiscoverConnections},
autodiscoverPort: ${autodiscoverPort},
refreshable: ${refreshable},
manualMode: ${manualMode},
domainMode: ${domainMode}
    ''';
  }
}
