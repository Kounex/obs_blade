import 'package:hive/hive.dart';

import 'type_ids.dart';

part 'hotkey.g.dart';

@HiveType(typeId: TypeIDs.Hotkey)
class Hotkey extends HiveObject {
  @HiveField(0)
  String name;

  Hotkey(this.name);
}
