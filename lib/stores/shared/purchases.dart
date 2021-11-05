import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mobx/mobx.dart';

part 'purchases.g.dart';

class PurchasesStore = _PurchasesStore with _$PurchasesStore;

abstract class _PurchasesStore with Store {
  @observable
  ObservableList<PurchaseDetails> purchases = ObservableList();

  @action
  void addPurchase(PurchaseDetails purchase) => this.purchases.add(purchase);
}
