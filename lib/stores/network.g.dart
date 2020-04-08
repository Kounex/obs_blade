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
