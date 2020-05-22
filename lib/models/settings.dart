import 'package:hive/hive.dart';

part 'settings.g.dart';

@HiveType(typeId: 2)
class Settings extends HiveObject {
  @HiveField(0)
  bool trueDark = false;

  @HiveField(1)
  bool reduceSmearing = false;
}
