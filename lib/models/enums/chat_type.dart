import 'package:hive/hive.dart';

part 'chat_type.g.dart';

@HiveType(typeId: 0)
enum ChatType {
  @HiveField(0)
  Twitch,

  @HiveField(1)
  YouTube,
}
