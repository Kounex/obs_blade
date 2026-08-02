import 'package:flutter/material.dart';

import '../../../../../models/app_log.dart';
import '../../../../../models/enums/log_level.dart';
import '../../../../../shared/design/design.dart';
import '../../../../../shared/general/base/card.dart';
import '../../../../../shared/general/column_separated.dart';
import '../../../../../shared/general/custom_expansion_tile.dart';
import '../../../../../types/extensions/list.dart';
import '../../../../../utils/styling_helper.dart';
import '../../widgets/level_dot.dart';

class LogEntry extends StatelessWidget {
  final String dateFormatted;
  final List<AppLog> logs;

  const LogEntry({super.key, required this.dateFormatted, required this.logs});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

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
                  Text(
                    dateFormatted,
                    style: textTheme.titleSmall?.copyWith(
                      fontFeatures: kTabularFigures,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  FittedBox(
                    child: Text(
                      '${this.logs.length} entries',
                      style: textTheme.bodySmall?.copyWith(
                        fontFeatures: kTabularFigures,
                      ),
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
                      if (groupedLogs.any((logs) =>
                          logs.any((log) => log.level == level))) ...[
                        const SizedBox(width: AppSpacing.md),
                        LevelDot(level: level, size: 8.0),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          level.name,
                          style: textTheme.bodySmall,
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
                      child: Text(
                        levelLogs.first.level.prefix,
                        style: textTheme.labelSmall?.copyWith(
                          color:
                              logLevelColor(context, levelLogs.first.level),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.only(left: 12.0),
                        margin: const EdgeInsets.only(left: 12.0),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: logLevelColor(
                                context,
                                levelLogs.first.level,
                              ).withOpacity(0.9),
                              width: 2.5,
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
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(log.entry),
                                        if (log.stackTrace != null)
                                          _StackTrace(
                                            stackTrace: log.stackTrace!,
                                          ),
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

/// Collapsible monospace stack trace - stays out of the way until asked for
class _StackTrace extends StatefulWidget {
  final String stackTrace;

  const _StackTrace({required this.stackTrace});

  @override
  State<_StackTrace> createState() => _StackTraceState();
}

class _StackTraceState extends State<_StackTrace> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final TextStyle? monoStyle =
        Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11.0,
              fontFamily:
                  StylingHelper.isApple(context) ? 'Menlo' : 'monospace',
            );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedRotation(
                  turns: _expanded ? 0.25 : 0.0,
                  duration: AppMotion.fast,
                  curve: AppMotion.standard,
                  child: Icon(
                    Icons.chevron_right,
                    size: 14.0,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Stack trace',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: AppMotion.medium,
          sizeCurve: AppMotion.standard,
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              this.widget.stackTrace,
              style: monoStyle,
            ),
          ),
        ),
      ],
    );
  }
}
