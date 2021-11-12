import 'package:hive/hive.dart';
import 'package:obs_blade/models/type_ids.dart';

part 'connection.g.dart';

@HiveType(typeId: TypeIDs.Connection)
class Connection extends HiveObject {
  @HiveField(0)
  String? name;

  @HiveField(1)
  String ip;

  @HiveField(2)
  String? ssid;

  @HiveField(3)
  int port;

  @HiveField(4)
  String? pw;

  String? challenge;
  String? salt;
  bool? reachable;

  Connection(this.ip, this.port, [this.pw]);
}
