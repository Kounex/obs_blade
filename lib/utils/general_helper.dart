import 'dart:developer';

import 'package:obs_blade/models/enums/log_level.dart';

class GeneralHelper {
  static void advLog(
    Object? obj, {
    LogLevel level = LogLevel.Info,
    bool includeInLogs = false,
  }) {
    String inLog = includeInLogs ? '[ON]' : '[OFF]';
    print(obj == null
        ? '${LogLevel.Warning.prefix}$inLog ${obj.runtimeType} is null!'
        : '${level.prefix}$inLog $obj');
  }
}
