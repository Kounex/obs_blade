// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'landing.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$LandingStore on _LandingStore, Store {
  final _$_refreshableAtom = Atom(name: '_LandingStore._refreshable');

  @override
  bool get _refreshable {
    _$_refreshableAtom.context.enforceReadPolicy(_$_refreshableAtom);
    _$_refreshableAtom.reportObserved();
    return super._refreshable;
  }

  @override
  set _refreshable(bool value) {
    _$_refreshableAtom.context.conditionallyRunInAction(() {
      super._refreshable = value;
      _$_refreshableAtom.reportChanged();
    }, _$_refreshableAtom, name: '${_$_refreshableAtom.name}_set');
  }

  final _$_obsNetworkAddressesAtom =
      Atom(name: '_LandingStore._obsNetworkAddresses');

  @override
  Future<List<NetworkAddress>> get _obsNetworkAddresses {
    _$_obsNetworkAddressesAtom.context
        .enforceReadPolicy(_$_obsNetworkAddressesAtom);
    _$_obsNetworkAddressesAtom.reportObserved();
    return super._obsNetworkAddresses;
  }

  @override
  set _obsNetworkAddresses(Future<List<NetworkAddress>> value) {
    _$_obsNetworkAddressesAtom.context.conditionallyRunInAction(() {
      super._obsNetworkAddresses = value;
      _$_obsNetworkAddressesAtom.reportChanged();
    }, _$_obsNetworkAddressesAtom,
        name: '${_$_obsNetworkAddressesAtom.name}_set');
  }

  final _$_LandingStoreActionController =
      ActionController(name: '_LandingStore');

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
  void updateObsNetworkAddresses() {
    final _$actionInfo = _$_LandingStoreActionController.startAction();
    try {
      return super.updateObsNetworkAddresses();
    } finally {
      _$_LandingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    final string = '';
    return '{$string}';
  }
}
