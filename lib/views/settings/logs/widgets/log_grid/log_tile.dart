import 'package:flutter/material.dart';
import '../../../../../models/app_log.dart';
import '../../../../../models/enums/log_level.dart';
import '../../../../../shared/animator/status_dot.dart';

import '../../../../../types/extensions/int.dart';
import '../../../../../utils/routing_helper.dart';

class LogTile extends StatelessWidget {
  final int dateMS;
  final List<AppLog> logs;

  const LogTile({Key? key, required this.dateMS, required this.logs})
      : super(key: key);

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
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Icon(
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
