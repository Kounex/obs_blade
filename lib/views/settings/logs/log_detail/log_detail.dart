import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../models/app_log.dart';
import '../../../../models/enums/log_level.dart';
import '../../../../shared/dialogs/confirmation.dart';
import '../../../../shared/general/app_bar_cupertino_actions.dart';
import '../../../../shared/general/base/base_card.dart';
import '../../../../shared/general/cupertino_dropdown.dart';
import '../../../../shared/general/hive_builder.dart';
import '../../../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import '../../../../shared/overlay/base_result.dart';
import '../../../../stores/views/logs.dart';
import '../../../../types/enums/hive_keys.dart';
import '../../../../types/extensions/int.dart';
import '../../../../utils/general_helper.dart';
import '../../../../utils/modal_handler.dart';
import 'widgets/log_entry.dart';

class LogDetailView extends StatelessWidget {
  const LogDetailView({Key? key}) : super(key: key);

  Future<File?> _createLogFile(
      List<Map<String, String>> jsonLogs, int timestampMS) async {
    File logFile = File((await Directory.systemTemp.createTemp()).path +
        '/${timestampMS.millisecondsToFileNameDate()}_obs_logs.json');

    try {
      logFile = await logFile.writeAsString(jsonEncode(jsonLogs));

      return logFile;
    } catch (e) {
      GeneralHelper.advLog(
        'Unable to create log file!\n$e',
        level: LogLevel.Error,
        includeInLogs: true,
      );
    }
  }

  Map<String, String> _addLogMetaData(String date, AppLog log) {
    Map<String, String> logEntry = {};
    logEntry.putIfAbsent('date', () => date);
    logEntry.putIfAbsent('level', () => log.level.name);
    logEntry.putIfAbsent('manual', () => log.manually.toString());

    return logEntry;
  }

  Future<void> _createLogFileAndExport(
      Map<String, List<AppLog>> mergedLogs) async {
    List<Map<String, String>> jsonLogs = [];

    for (var dateLog in mergedLogs.entries) {
      Map<String, String> logEntry =
          _addLogMetaData(dateLog.key, dateLog.value.first);

      for (var log in dateLog.value) {
        if (log.level.name != logEntry['level']) {
          jsonLogs.add(logEntry);
          logEntry = _addLogMetaData(dateLog.key, log);
        }

        logEntry['entry'] =
            (logEntry['entry'] != null ? logEntry['entry']! + '\n' : '') +
                log.entry +
                (log.stackTrace != null ? '\n${log.stackTrace}' : '');
      }

      jsonLogs.add(logEntry);
    }

    File? logFile = await _createLogFile(
        jsonLogs, mergedLogs.values.first.first.timestampMS);

    if (logFile != null) {
      try {
        await Share.shareFiles([logFile.path], subject: 'OBS Blade Log');
      } catch (e) {
        GeneralHelper.advLog(
          'Unable to share log file!\n$e',
          level: LogLevel.Error,
          includeInLogs: true,
        );
      }
    }
  }

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
                          log.timestampMS
                              .millisecondsToFormattedTimeString(true),
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
                    onAction: () => _createLogFileAndExport(mergedLogs),
                  ),
                  AppBarCupertinoActionEntry(
                    title: 'Delete',
                    isDestructive: true,
                    onAction: () {
                      ModalHandler.showBaseDialog(
                        context: context,
                        dialogWidget: ConfirmationDialog(
                            title: 'Delete Logs',
                            body:
                                'Are you sure you want to delete all logs listed here? This action can\'t be undone!',
                            isYesDestructive: true,
                            onOk: (_) {
                              for (var logList in mergedLogs.values) {
                                for (var log in logList) {
                                  log.isInBox ? log.delete() : null;
                                }
                              }
                              Navigator.of(context).pop();
                            }),
                      );
                    },
                  )
                ],
              ),
              listViewChildren: [
                Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: kBaseCardMaxWidth),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 102.0,
                          child: CupertinoDropdown<LogLevel>(
                            value: logsStore.logLevel,
                            items: [
                              const DropdownMenuItem(
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
                  ),
                ),
                ...mergedLogs.entries.map(
                  (mergedLog) => LogEntry(
                    dateFormatted: mergedLog.key,
                    logs: mergedLog.value,
                  ),
                ),
                if (mergedLogs.entries.isEmpty)
                  BaseCard(
                    child: BaseResult(
                      icon: BaseResultIcon.Missing,
                      text:
                          'No logs found for type: ${logsStore.logLevel!.name}',
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
