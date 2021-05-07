import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'package:share/share.dart';
import 'package:get_it/get_it.dart';

import '../../../../models/app_log.dart';
import '../../../../models/enums/log_level.dart';
import '../../../../shared/general/app_bar_cupertino_actions.dart';
import '../../../../shared/general/cupertino_dropdown.dart';
import '../../../../shared/general/hive_builder.dart';
import '../../../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import '../../../../stores/views/logs.dart';
import '../../../../types/enums/hive_keys.dart';
import '../../../../types/extensions/int.dart';
import 'widgets/log_entry.dart';

class LogDetailView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    LogsStore logsStore = GetIt.instance<LogsStore>();
    int dateMS = ModalRoute.of(context)!.settings.arguments as int;

    return Scaffold(
      body: HiveBuilder<AppLog>(
        hiveKey: HiveKeys.AppLog,
        builder: (context, appLogBox, child) => Observer(
          builder: (_) {
            Map<String, List<AppLog>> mergedLogs = {};

            List<AppLog>.from(appLogBox.values)
                .reversed
                .where((log) =>
                    (logsStore.logLevel != null
                        ? log.level == logsStore.logLevel
                        : true) &&
                    log.timestampMS.millisecondsSameDay(dateMS))
                .forEach(
                  (log) => mergedLogs
                      .putIfAbsent(
                          log.timestampMS.millisecondsToFormattedTimeString(),
                          () => [])
                      .add(log),
                );

            return TransculentCupertinoNavBarWrapper(
              previousTitle: 'Logs',
              title: dateMS.millisecondsToFormattedDateString(),
              showScrollBar: true,
              actions: AppBarCupertinoActions(
                actions: [
                  AppBarCupertinoActionEntry(
                    title: 'Export',
                    onAction: () {
                      String condensedLog = '';

                      mergedLogs.entries.forEach((dateLog) {
                        condensedLog += '<---${dateLog.key}--->\n';

                        dateLog.value.forEach((log) {
                          condensedLog += 'Level: ${log.level.name}\n';
                          condensedLog += 'Manually: ${log.manually}\n\n';
                          condensedLog += 'Entry: ${log.entry}\n';
                          if (log.stackTrace != null)
                            condensedLog += 'StackTrace: ${log.stackTrace}\n';
                        });

                        condensedLog += '<--------------->';
                      });

                      Share.share(condensedLog, subject: 'OBS Blade Log');
                    },
                  ),
                  AppBarCupertinoActionEntry(
                    title: 'Delete',
                    isDestructive: true,
                    onAction: () {
                      mergedLogs.values.forEach(
                        (logList) => logList.forEach(
                            (log) => log.isInBox ? log.delete() : null),
                      );
                      Navigator.of(context).pop();
                    },
                  )
                ],
              ),
              listViewChildren: [
                Padding(
                  padding: EdgeInsets.only(left: 24.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 102.0,
                      child: CupertinoDropdown<LogLevel>(
                        value: logsStore.logLevel,
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text('All'),
                          ),
                          ...LogLevel.values.map(
                            (logLevel) => DropdownMenuItem(
                              value: logLevel,
                              child: Text(logLevel.name),
                            ),
                          ),
                        ],
                        onChanged: (logLevel) =>
                            logsStore.setLogLevel(logLevel),
                      ),
                    ),
                  ),
                ),
                ...mergedLogs.entries.map(
                  (mergedLog) => LogEntry(
                    dateFormatted: mergedLog.key,
                    logs: mergedLog.value,
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }
}
