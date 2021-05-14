import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/models/app_log.dart';
import 'package:obs_blade/models/enums/log_level.dart';
import 'package:obs_blade/shared/animator/status_dot.dart';

import '../../../../../types/extensions/int.dart';
import '../../../../../utils/routing_helper.dart';

class LogTile extends StatelessWidget {
  final int dateMS;
  final List<AppLog> logs;

  LogTile({required this.dateMS, required this.logs});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        children: [
          SizedBox(
            width: 92.0,
            child: Text(
              this.dateMS.millisecondsToFormattedDateString(),
            ),
          ),
          ...LogLevel.values
              .where((level) => this.logs.any((log) => log.level == level))
              .map((level) => StatusDot(
                    text: '',
                    color: level.color,
                    // size: logs.where((log) => log.level == level).length /
                    //         logs.length *
                    //         5 +
                    //     7.0,
                  )),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${this.logs.length} entries',
            style: Theme.of(context).textTheme.caption,
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.grey,
          ),
        ],
      ),
      onTap: () => Navigator.of(context).pushNamed(
        SettingsTabRoutingKeys.LogDetail.route,
        arguments: this.dateMS,
      ),
    );
  }
}
