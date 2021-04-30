import 'package:flutter/material.dart';
import 'package:obs_blade/models/app_log.dart';
import 'package:obs_blade/shared/general/base_card.dart';
import 'package:obs_blade/shared/general/column_separated.dart';
import 'package:obs_blade/utils/styling_helper.dart';

import '../../../../../types/extensions/list.dart';

class LogEntry extends StatelessWidget {
  final String dateFormatted;
  final List<AppLog> logs;

  LogEntry({required this.dateFormatted, required this.logs});

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      bottomPadding: 12.0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(this.dateFormatted),
          Expanded(
            child: Container(
              padding: EdgeInsets.only(left: 12.0),
              margin: EdgeInsets.only(left: 12.0),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: StylingHelper.light_divider_color,
                    width: 1.0,
                  ),
                ),
              ),
              child: ColumnSeparated(
                children: [
                  ...this.logs.mapIndexed(
                        (log, index) => Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              index.toString(),
                            ),
                            SizedBox(width: 12.0),
                            Expanded(
                              child: Text(log.entry),
                            )
                          ],
                        ),
                      )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
