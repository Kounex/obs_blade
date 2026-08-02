import 'package:flutter/material.dart';

import '../../../../models/enums/log_level.dart';
import '../../../../shared/design/design.dart';

/// Semantic color per log level: Warning/Error map onto the theme-registered
/// status colors, Info keeps its established blue (no matching status slot).
/// Level semantics (blue / amber / red) are preserved.
Color logLevelColor(BuildContext context, LogLevel level) {
  final AppStatusColors statusColors = Theme.of(
    context,
  ).extension<AppStatusColors>()!;
  return switch (level) {
    LogLevel.Info => Colors.lightBlueAccent,
    LogLevel.Warning => statusColors.warning,
    LogLevel.Error => statusColors.recording,
  };
}

/// Static level indicator - deliberately NOT the perpetually pulsing
/// `StatusDot`, since logs are static historical data and an infinite
/// pulse reads as "live".
class LevelDot extends StatelessWidget {
  final LogLevel level;
  final double size;

  const LevelDot({super.key, required this.level, this.size = 10.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: this.size,
      height: this.size,
      decoration: BoxDecoration(
        color: logLevelColor(context, this.level),
        shape: BoxShape.circle,
      ),
    );
  }
}
