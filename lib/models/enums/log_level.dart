import 'package:hive/hive.dart';

part 'log_level.g.dart';

@HiveType(typeId: 8)
enum LogLevel {
  @HiveField(0)
  Info,

  @HiveField(1)
  Warning,

  @HiveField(2)
  Error,
}
