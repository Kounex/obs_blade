import 'package:flutter/material.dart';

import '../../../../models/enums/dashboard_element.dart';
import '../../../../shared/general/custom_sliver_list.dart';
import '../../../../shared/general/hive_builder.dart';
import '../../../../types/enums/hive_keys.dart';
import '../../../../types/enums/settings_keys.dart';
import 'dashboard_element_layout.dart';

class DashboardContent extends StatelessWidget {
  const DashboardContent({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [SettingsKeys.DashboardElementsOrder],
      builder: (context, settingsBox, child) {
        final List<DashboardElement> order = [
          ...settingsBox.get(
            SettingsKeys.DashboardElementsOrder.name,
            defaultValue: DashboardElement.values,
          ),
        ];

        return CustomSliverList(
          children: buildOrderedDashboardSlivers(order),
        );
      },
    );
  }
}
