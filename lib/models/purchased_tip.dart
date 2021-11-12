import 'package:hive/hive.dart';

part 'purchased_tip.g.dart';

@HiveType(typeId: 9)
class PurchasedTip extends HiveObject {
  @HiveField(0)
  int timestampMS;

  @HiveField(1)
  String id;

  @HiveField(2)
  String name;

  @HiveField(3)
  String price;

  PurchasedTip(this.timestampMS, this.id, this.name, this.price);
}
