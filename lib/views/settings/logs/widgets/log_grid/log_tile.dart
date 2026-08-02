import 'package:flutter/material.dart';

import '../../../../../models/app_log.dart';
import '../../../../../models/enums/log_level.dart';
import '../../../../../shared/design/design.dart';
import '../../../../../types/extensions/int.dart';
import '../../../../../utils/routing_helper.dart';
import '../level_dot.dart';

class LogTile extends StatelessWidget {
  final int dateMS;
  final List<AppLog> logs;

  const LogTile({super.key, required this.dateMS, required this.logs});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Pressable(
      onTap: () => Navigator.of(context).pushNamed(
        SettingsTabRoutingKeys.LogDetail.route,
        arguments: this.dateMS,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 102.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    this.dateMS.millisecondsToFormattedDateString(),
                    style: textTheme.titleSmall?.copyWith(
                      fontFeatures: kTabularFigures,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${this.logs.length} entries',
                    style: textTheme.bodySmall?.copyWith(
                      fontFeatures: kTabularFigures,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  for (LogLevel level in LogLevel.values.where((level) =>
                      this.logs.any((log) => log.level == level))) ...[
                    LevelDot(level: level, size: 8.0),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${this.logs.where((log) => log.level == level).length}',
                      style: textTheme.bodySmall?.copyWith(
                        fontFeatures: kTabularFigures,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: textTheme.bodySmall?.color,
            ),
          ],
        ),
      ),
    );
  }
}
