import 'package:flutter/material.dart';
import 'package:obs_blade/models/app_log.dart';
import 'package:obs_blade/models/enums/log_level.dart';
import 'package:obs_blade/shared/animator/status_dot.dart';
import 'package:obs_blade/shared/general/base_card.dart';
import 'package:obs_blade/shared/general/column_separated.dart';
import 'package:obs_blade/shared/general/custom_expansion_tile.dart';
import 'package:obs_blade/utils/general_helper.dart';
import 'package:obs_blade/utils/styling_helper.dart';

import '../../../../../types/extensions/list.dart';

class LogEntry extends StatelessWidget {
  final String dateFormatted;
  final List<AppLog> logs;

  LogEntry({required this.dateFormatted, required this.logs});

  @override
  Widget build(BuildContext context) {
    List<List<AppLog>> groupedLogs = [];

    List<AppLog> temp = [];
    this.logs.forEach((log) {
      if (temp.isEmpty || temp.last.level == log.level) {
        temp.add(log);
      } else {
        groupedLogs.add([...temp]);
        temp.clear();
      }
    });
    if (temp.isNotEmpty) groupedLogs.add([...temp]);

    return BaseCard(
      topPadding: 12.0,
      bottomPadding: 0.0,
      paddingChild: const EdgeInsets.all(12.0),
      child: CustomExpansionTile(
        customHeader: Row(
          children: [
            SizedBox(
              width: 84.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).textTheme.bodyText1!.color!,
                        ),
                      ),
                    ),
                    child: Text(dateFormatted),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    '${this.logs.length} entries',
                    style: Theme.of(context).textTheme.caption,
                  ),
                ],
              ),
            ),
            for (LogLevel level in LogLevel.values) ...[
              if (groupedLogs
                  .any((logs) => logs.any((log) => log.level == level))) ...[
                SizedBox(width: 12.0),
                SizedBox(
                  width: 64.0,
                  child: StatusDot(
                    text: level.name,
                    color: level.color,
                    direction: Axis.vertical,
                  ),
                ),
              ],
            ],
          ],
        ),
        expandedBody: ColumnSeparated(
          children: [
            Container(),
            ...groupedLogs.map((levelLogs) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(levelLogs.first.level.prefix),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.only(left: 12.0),
                        margin: EdgeInsets.only(left: 12.0),
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
                                  Text(
                                    index.toString(),
                                  ),
                                  SizedBox(width: 12.0),
                                  Expanded(
                                    child: Column(
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
