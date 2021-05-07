import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:obs_blade/types/enums/order.dart';
import 'package:get_it/get_it.dart';

import '../../../../../models/app_log.dart';
import '../../../../../shared/general/base_card.dart';
import '../../../../../shared/general/hive_builder.dart';
import '../../../../../shared/overlay/base_result.dart';
import '../../../../../stores/views/logs.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/extensions/int.dart';
import 'log_box.dart';

class LogGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    LogsStore logsStore = GetIt.instance<LogsStore>();

    return Center(
      child: Padding(
        padding: EdgeInsets.only(
          top: 12.0,
          left: 24.0,
          right: 24.0,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: kBaseCardMaxWidth),
          child: LayoutBuilder(builder: (context, constraints) {
            double maxSize = 124.0;
            double spacing = 24.0;
            double constrainedWidth =
                min(kBaseCardMaxWidth, constraints.maxWidth);
            double outterSpace = MediaQuery.of(context).padding.left +
                MediaQuery.of(context).padding.right;
            double size = (constrainedWidth - (3 * spacing + outterSpace)) / 3;

            return HiveBuilder<AppLog>(
                hiveKey: HiveKeys.AppLog,
                builder: (context, appLogBox, child) {
                  return Observer(builder: (_) {
                    List<int> datesMSWithLogs = [];

                    Iterable<AppLog> filteredOrderedLogs =
                        appLogBox.values.where((log) {
                      bool reqMet = true;

                      if (logsStore.fromDate != null)
                        reqMet = log.timestampMS >=
                            logsStore.fromDate!.millisecondsSinceEpoch;

                      if (logsStore.toDate != null)
                        reqMet = log.timestampMS <=
                            logsStore.toDate!.millisecondsSinceEpoch;

                      if (logsStore.logLevel != null)
                        reqMet = log.level == logsStore.logLevel;

                      return reqMet;
                    }).toList()
                          ..sort(
                            (log1, log2) => logsStore.filterOrder ==
                                    Order.Descending
                                ? log2.timestampMS.compareTo(log1.timestampMS)
                                : log1.timestampMS.compareTo(log2.timestampMS),
                          );

                    if (logsStore.amountLogEntries != null)
                      filteredOrderedLogs = filteredOrderedLogs
                          .take(logsStore.amountLogEntries!.number);

                    filteredOrderedLogs.forEach((log) {
                      if (!datesMSWithLogs.any((dateMS) =>
                          dateMS.millisecondsSameDay(log.timestampMS))) {
                        datesMSWithLogs.add(log.timestampMS);
                      }
                    });

                    return Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        if (datesMSWithLogs.isEmpty)
                          BaseCard(
                            topPadding: 0,
                            child: BaseResult(
                              icon: BaseResultIcon.Missing,
                              text: 'No logs found!',
                            ),
                          ),
                        ...datesMSWithLogs.map(
                          (dateMS) => LogBox(
                            dateMS: dateMS,
                            size: size > maxSize ? maxSize : size,
                          ),
                        ),
                      ],
                    );
                  });
                });
          }),
        ),
      ),
    );
  }
}
