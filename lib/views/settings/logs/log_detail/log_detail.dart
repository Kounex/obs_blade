import 'package:flutter/material.dart';
import 'package:obs_blade/utils/general_helper.dart';

import '../../../../models/app_log.dart';
import '../../../../shared/general/hive_builder.dart';
import '../../../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import '../../../../types/enums/hive_keys.dart';
import '../../../../types/extensions/int.dart';
import 'widgets/log_entry.dart';

class LogDetailView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    int dateMS = ModalRoute.of(context)!.settings.arguments as int;

    return Scaffold(
      body: HiveBuilder<AppLog>(
        hiveKey: HiveKeys.AppLog,
        builder: (context, appLogBox, child) {
          Map<String, List<AppLog>> mergedLogs = {};

          List<AppLog>.from(appLogBox.values)
              .reversed
              .where((log) => log.timestampMS.millisecondsSameDay(dateMS))
              .forEach(
                (log) => mergedLogs
                    .putIfAbsent(
                        log.timestampMS.millisecondsToFormattedTimeString(),
                        () => [log])
                    .add(log),
              );

          return TransculentCupertinoNavBarWrapper(
            previousTitle: 'Logs',
            title: dateMS.millisecondsToFormattedDateString(),
            showScrollBar: true,
            listViewChildren: [
              ...mergedLogs.entries.map(
                (mergedLog) => LogEntry(
                    dateFormatted: mergedLog.key, logs: mergedLog.value),
              )
            ],
          );
        },
      ),
    );
  }
}
