import 'package:flutter/material.dart';

import '../../../../../shared/design/design.dart';
import '../../../../dashboard/widgets/obs_widgets/stats/stat_tile.dart';

/// Uses the real [StatTile] leaf (same telemetry tile as the dashboard
/// stats pager) with static readouts — no [DashboardStore].
class StatsPreview extends StatelessWidget {
  const StatsPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            StatTile(label: 'FPS', text: '60', width: 72.0),
            SizedBox(width: AppSpacing.sm),
            StatTile(label: 'CPU*', text: '12.4', unit: '%', width: 84.0),
          ],
        ),
      ),
    );
  }
}
