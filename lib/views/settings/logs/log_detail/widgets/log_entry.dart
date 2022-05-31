import 'package:flutter/material.dart';

import '../../../../../models/app_log.dart';
import '../../../../../models/enums/log_level.dart';
import '../../../../../shared/animator/status_dot.dart';
import '../../../../../shared/general/base/card.dart';
import '../../../../../shared/general/column_separated.dart';
import '../../../../../shared/general/custom_expansion_tile.dart';
import '../../../../../types/extensions/list.dart';

class LogEntry extends StatelessWidget {
  final String dateFormatted;
  final List<AppLog> logs;

  const LogEntry({Key? key, required this.dateFormatted, required this.logs})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<List<AppLog>> groupedLogs = [];

    List<AppLog> temp = [];
    for (var log in this.logs) {
      if (temp.isEmpty || temp.last.level == log.level) {
        temp.add(log);
      } else {
        temp.sort((log1, log2) => log1.timestampMS.compareTo(log2.timestampMS));
        groupedLogs.add([...temp]);
        temp.clear();
        temp.add(log);
      }
    }
    if (temp.isNotEmpty) {
      temp.sort((log1, log2) => log1.timestampMS.compareTo(log2.timestampMS));
      groupedLogs.add([...temp]);
    }

    return BaseCard(
      topPadding: 12.0,
      bottomPadding: 0.0,
      paddingChild: const EdgeInsets.all(12.0),
      child: CustomExpansionTile(
        customHeader: Row(
          children: [
            SizedBox(
              width: 64.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context)
                              .textTheme
                              .bodyText1!
                              .color!
                              .withOpacity(0.5),
                        ),
                      ),
                    ),
                    child: Text(dateFormatted),
                  ),
                  const SizedBox(height: 4.0),
                  FittedBox(
                    child: Text(
                      '${this.logs.length} entries',
                      style: Theme.of(context).textTheme.caption,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: FittedBox(
                child: Row(
                  children: [
                    for (LogLevel level in LogLevel.values) ...[
                      if (groupedLogs.any(
                          (logs) => logs.any((log) => log.level == level))) ...[
                        const SizedBox(width: 12.0),
                        SizedBox(
                          width: 48.0,
                          child: StatusDot(
                            text: level.name,
                            style: Theme.of(context)
                                .textTheme
                                .bodyText1!
                                .copyWith(fontSize: 12.0),
                            verticalSpacing: 6.0,
                            color: level.color,
                            direction: Axis.vertical,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        expandedBody: ColumnSeparated(
          children: [
            Container(),
            ...groupedLogs.map((levelLogs) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 84.0,
                      child: Text(levelLogs.first.level.prefix),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.only(left: 12.0),
                        margin: const EdgeInsets.only(left: 12.0),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: levelLogs.first.level.color,
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: ColumnSeparated(
                          paddingSeparator:
                              const EdgeInsets.symmetric(vertical: 4.0),
                          children: [
                            ...levelLogs.mapIndexed(
                              (log, index) => Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Text(
                                  //   (index + 1).toString(),
                                  // ),
                                  // SizedBox(width: 12.0),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(log.entry),
                                        if (log.stackTrace != null)
                                          Text(
                                            log.stackTrace!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .caption,
                                          )
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ))
          ],
        ),
      ),
    );
  }
}
