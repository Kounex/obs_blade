// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pro_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ProStore on _ProStore, Store {
  Computed<bool>? _$isProComputed;

  @override
  bool get isPro => (_$isProComputed ??= Computed<bool>(
    () => super.isPro,
    name: '_ProStore.isPro',
  )).value;

  late final _$boughtProAtom = Atom(
    name: '_ProStore.boughtPro',
    context: context,
  );

  @override
  bool get boughtPro {
    _$boughtProAtom.reportRead();
    return super.boughtPro;
  }

  @override
  set boughtPro(bool value) {
    _$boughtProAtom.reportWrite(value, super.boughtPro, () {
      super.boughtPro = value;
    });
  }

  late final _$debugOverrideAtom = Atom(
    name: '_ProStore.debugOverride',
    context: context,
  );

  @override
  bool get debugOverride {
    _$debugOverrideAtom.reportRead();
    return super.debugOverride;
  }

  @override
  set debugOverride(bool value) {
    _$debugOverrideAtom.reportWrite(value, super.debugOverride, () {
      super.debugOverride = value;
    });
  }

  late final _$pendingAtom = Atom(name: '_ProStore.pending', context: context);

  @override
  bool get pending {
    _$pendingAtom.reportRead();
    return super.pending;
  }

  @override
  set pending(bool value) {
    _$pendingAtom.reportWrite(value, super.pending, () {
      super.pending = value;
    });
  }

  late final _$lastErrorAtom = Atom(
    name: '_ProStore.lastError',
    context: context,
  );

  @override
  String? get lastError {
    _$lastErrorAtom.reportRead();
    return super.lastError;
  }

  @override
  set lastError(String? value) {
    _$lastErrorAtom.reportWrite(value, super.lastError, () {
      super.lastError = value;
    });
  }

  late final _$productsLoadedAtom = Atom(
    name: '_ProStore.productsLoaded',
    context: context,
  );

  @override
  bool get productsLoaded {
    _$productsLoadedAtom.reportRead();
    return super.productsLoaded;
  }

  @override
  set productsLoaded(bool value) {
    _$productsLoadedAtom.reportWrite(value, super.productsLoaded, () {
      super.productsLoaded = value;
    });
  }

  late final _$loadProductsAsyncAction = AsyncAction(
    '_ProStore.loadProducts',
    context: context,
  );

  @override
  Future<void> loadProducts() {
    return _$loadProductsAsyncAction.run(() => super.loadProducts());
  }

  late final _$buyAsyncAction = AsyncAction('_ProStore.buy', context: context);

  @override
  Future<bool> buy(ProductDetails product) {
    return _$buyAsyncAction.run(() => super.buy(product));
  }

  late final _$restoreAsyncAction = AsyncAction(
    '_ProStore.restore',
    context: context,
  );

  @override
  Future<void> restore({required bool explicit}) {
    return _$restoreAsyncAction.run(() => super.restore(explicit: explicit));
  }

  late final _$_ProStoreActionController = ActionController(
    name: '_ProStore',
    context: context,
  );

  @override
  void setDebugOverride(bool value) {
    final _$actionInfo = _$_ProStoreActionController.startAction(
      name: '_ProStore.setDebugOverride',
    );
    try {
      return super.setDebugOverride(value);
    } finally {
      _$_ProStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
boughtPro: ${boughtPro},
debugOverride: ${debugOverride},
pending: ${pending},
lastError: ${lastError},
productsLoaded: ${productsLoaded},
isPro: ${isPro}
    ''';
  }
}
