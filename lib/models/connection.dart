import 'package:hive/hive.dart';
import 'type_ids.dart';

part 'connection.g.dart';

@HiveType(typeId: TypeIDs.Connection)
class Connection extends HiveObject {
  @HiveField(0)
  String? name;

  @HiveField(1)
  String host;

  @HiveField(2)
  String? ssid;

  @HiveField(3)
  int port;

  @HiveField(4)
  String? pw;

  @HiveField(5)
  bool? isDomain;

  String? challenge;
  String? salt;
  bool? reachable;

  Connection(this.host, this.port, [this.pw, this.isDomain]);
}
