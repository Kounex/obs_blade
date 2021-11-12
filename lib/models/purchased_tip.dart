import 'package:hive/hive.dart';
import 'package:obs_blade/models/type_ids.dart';

part 'purchased_tip.g.dart';

@HiveType(typeId: TypeIDs.PurchasedTip)
class PurchasedTip extends HiveObject {
  @HiveField(0)
  int timestampMS;

  @HiveField(1)
  String id;

  @HiveField(2)
  String name;

  @HiveField(3)
  String price;

  @HiveField(4)
  String currencySymbol;

  PurchasedTip(
      this.timestampMS, this.id, this.name, this.price, this.currencySymbol);
}
