import 'package:hive/hive.dart';
import 'type_ids.dart';

import 'enums/log_level.dart';

part 'app_log.g.dart';

@HiveType(typeId: TypeIDs.AppLog)
class AppLog extends HiveObject {
  @HiveField(0)
  int timestampMS;

  @HiveField(1)
  LogLevel level;

  @HiveField(2)
  String entry;

  @HiveField(3)
  String? stackTrace;

  @HiveField(4)
  bool manually;

  AppLog(this.timestampMS, this.level, this.entry,
      [this.stackTrace, this.manually = false]);
}
