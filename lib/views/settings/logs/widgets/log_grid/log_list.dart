import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../models/app_log.dart';
import '../../../../../shared/general/base/base_card.dart';
import '../../../../../shared/general/column_separated.dart';
import '../../../../../shared/general/hive_builder.dart';
import '../../../../../shared/overlay/base_result.dart';
import '../../../../../stores/views/logs.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/order.dart';
import '../../../../../types/extensions/int.dart';
import 'log_tile.dart';

class LogList extends StatelessWidget {
  const LogList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    LogsStore logsStore = GetIt.instance<LogsStore>();

    return BaseCard(
      paddingChild: const EdgeInsets.all(0),
      child: HiveBuilder<AppLog>(
          hiveKey: HiveKeys.AppLog,
          builder: (context, appLogBox, child) {
            return Observer(builder: (_) {
              List<int> datesMSWithLogs = [];

              Iterable<AppLog> filteredOrderedLogs =
                  appLogBox.values.where((log) {
                bool reqMet = true;

                if (logsStore.fromDate != null) {
                  reqMet = log.timestampMS >=
                      logsStore.fromDate!.millisecondsSinceEpoch;
                }

                if (logsStore.toDate != null) {
                  reqMet = log.timestampMS <=
                      logsStore.toDate!.millisecondsSinceEpoch;
                }

                if (logsStore.logLevel != null) {
                  reqMet = log.level == logsStore.logLevel;
                }

                return reqMet;
              }).toList()
                    ..sort(
                      (log1, log2) => logsStore.filterOrder == Order.Descending
                          ? log2.timestampMS.compareTo(log1.timestampMS)
                          : log1.timestampMS.compareTo(log2.timestampMS),
                    );

              for (var log in filteredOrderedLogs) {
                if (!datesMSWithLogs.any(
                    (dateMS) => dateMS.millisecondsSameDay(log.timestampMS))) {
                  datesMSWithLogs.add(log.timestampMS);
                }
              }

              if (logsStore.amountLogEntries != null) {
                datesMSWithLogs = datesMSWithLogs
                    .take(logsStore.amountLogEntries!.number)
                    .toList();
              }

              return ColumnSeparated(
                paddingSeparator: const EdgeInsets.all(0),
                children: [
                  if (datesMSWithLogs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                      child: BaseResult(
                        icon: BaseResultIcon.Missing,
                        text: 'No logs found!',
                      ),
                    ),
                  ...datesMSWithLogs.map(
                    (dateMS) => LogTile(
                      dateMS: dateMS,
                      logs: filteredOrderedLogs
                          .where((log) =>
                              log.timestampMS.millisecondsSameDay(dateMS))
                          .toList(),
                    ),
                  ),
                ],
              );
            });
          }),
    );
  }
}
