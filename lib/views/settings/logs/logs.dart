import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/app_log.dart';
import '../../../shared/general/hive_builder.dart';
import '../../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import '../../../stores/views/logs.dart';
import '../../../types/enums/hive_keys.dart';
import '../../../types/extensions/int.dart';
import 'widgets/log_explanation.dart';
import 'widgets/log_grid/log_grid.dart';

class LogsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) => LogsStore(),
      child: _LogsView(),
    );
  }
}

class _LogsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HiveBuilder<AppLog>(
        hiveKey: HiveKeys.AppLog,
        builder: (context, appLogBox, child) {
          List<int> datesMSWithLogs = [];

          appLogBox.values.forEach((log) {
            if (!datesMSWithLogs
                .any((dateMS) => dateMS.millisecondsSameDay(log.timestampMS))) {
              datesMSWithLogs.add(log.timestampMS);
            }
          });

          return TransculentCupertinoNavBarWrapper(
            previousTitle: 'Settings',
            title: 'Logs',
            showScrollBar: true,
            listViewChildren: [
              LogExplanation(),
              LogGrid(datesMSWithLogs: datesMSWithLogs),
            ],
          );
        },
      ),
    );
  }
}
