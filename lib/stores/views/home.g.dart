// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$HomeStore on _HomeStore, Store {
  late final _$autodiscoverConnectionsAtom =
      Atom(name: '_HomeStore.autodiscoverConnections', context: context);

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

  late final _$autodiscoverPortAtom =
      Atom(name: '_HomeStore.autodiscoverPort', context: context);

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

  late final _$refreshableAtom =
      Atom(name: '_HomeStore.refreshable', context: context);

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

  late final _$doRefreshAtom =
      Atom(name: '_HomeStore.doRefresh', context: context);

  @override
  bool get doRefresh {
    _$doRefreshAtom.reportRead();
    return super.doRefresh;
  }

  @override
  set doRefresh(bool value) {
    _$doRefreshAtom.reportWrite(value, super.doRefresh, () {
      super.doRefresh = value;
    });
  }

  late final _$connectModeAtom =
      Atom(name: '_HomeStore.connectMode', context: context);

  @override
  ConnectMode get connectMode {
    _$connectModeAtom.reportRead();
    return super.connectMode;
  }

  @override
  set connectMode(ConnectMode value) {
    _$connectModeAtom.reportWrite(value, super.connectMode, () {
      super.connectMode = value;
    });
  }

  late final _$domainModeAtom =
      Atom(name: '_HomeStore.domainMode', context: context);

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

  late final _$protocolSchemeAtom =
      Atom(name: '_HomeStore.protocolScheme', context: context);

  @override
  String get protocolScheme {
    _$protocolSchemeAtom.reportRead();
    return super.protocolScheme;
  }

  @override
  set protocolScheme(String value) {
    _$protocolSchemeAtom.reportWrite(value, super.protocolScheme, () {
      super.protocolScheme = value;
    });
  }

  late final _$_HomeStoreActionController =
      ActionController(name: '_HomeStore', context: context);

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
  void initiateRefresh() {
    final _$actionInfo = _$_HomeStoreActionController.startAction(
        name: '_HomeStore.initiateRefresh');
    try {
      return super.initiateRefresh();
    } finally {
      _$_HomeStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setProtocolScheme(String protocolScheme) {
    final _$actionInfo = _$_HomeStoreActionController.startAction(
        name: '_HomeStore.setProtocolScheme');
    try {
      return super.setProtocolScheme(protocolScheme);
    } finally {
      _$_HomeStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setConnectMode(ConnectMode connectMode) {
    final _$actionInfo = _$_HomeStoreActionController.startAction(
        name: '_HomeStore.setConnectMode');
    try {
      return super.setConnectMode(connectMode);
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
doRefresh: ${doRefresh},
connectMode: ${connectMode},
domainMode: ${domainMode},
protocolScheme: ${protocolScheme}
    ''';
  }
}
