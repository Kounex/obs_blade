import 'package:hive/hive.dart';

import 'enums/log_level.dart';

part 'app_log.g.dart';

@HiveType(typeId: 7)
class AppLog extends HiveObject {
  @HiveField(0)
  int timestampMS;

  @HiveField(1)
  LogLevel level;

  @HiveField(2)
  String entry;

  @HiveField(3)
  String? stackTrace;

  AppLog(this.timestampMS, this.level, this.entry, [this.stackTrace]);
}
