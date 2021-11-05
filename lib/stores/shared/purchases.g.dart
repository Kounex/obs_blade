// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchases.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$PurchasesStore on _PurchasesStore, Store {
  final _$purchasesAtom = Atom(name: '_PurchasesStore.purchases');

  @override
  ObservableList<PurchaseDetails> get purchases {
    _$purchasesAtom.reportRead();
    return super.purchases;
  }

  @override
  set purchases(ObservableList<PurchaseDetails> value) {
    _$purchasesAtom.reportWrite(value, super.purchases, () {
      super.purchases = value;
    });
  }

  final _$_PurchasesStoreActionController =
      ActionController(name: '_PurchasesStore');

  @override
  void addPurchase(PurchaseDetails purchase) {
    final _$actionInfo = _$_PurchasesStoreActionController.startAction(
        name: '_PurchasesStore.addPurchase');
    try {
      return super.addPurchase(purchase);
    } finally {
      _$_PurchasesStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
purchases: ${purchases}
    ''';
  }
}
