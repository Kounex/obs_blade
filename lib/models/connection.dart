import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class Connection extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String ip;

  @HiveField(2)
  int port;

  @HiveField(3)
  String pw;

  String challenge;
  String salt;

  Connection(this.ip, this.port, [this.pw]);
}
