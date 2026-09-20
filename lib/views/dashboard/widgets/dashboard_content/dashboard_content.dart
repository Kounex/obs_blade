import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../models/enums/dashboard_element.dart';
import '../../../../shared/general/custom_sliver_list.dart';
import '../../../../shared/general/hive_builder.dart';
import '../../../../stores/views/dashboard.dart';
import '../../../../types/enums/hive_keys.dart';
import '../../../../types/enums/settings_keys.dart';
import 'dashboard_element_layout.dart';

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [
        SettingsKeys.DashboardElementsOrder,
        SettingsKeys.ExposeProfile,
        SettingsKeys.ExposeSceneCollection,
        SettingsKeys.ExposeStreamingControls,
        SettingsKeys.ExposeRecordingControls,
        SettingsKeys.ExposeReplayBufferControls,
        SettingsKeys.ExposeHotkeys,
        SettingsKeys.ExposeStudioControls,
      ],
      builder: (context, settingsBox, child) {
        final List<DashboardElement> order =
            [
                ...settingsBox.get(
                  SettingsKeys.DashboardElementsOrder.name,
                  defaultValue: DashboardElement.values,
                ),
              ]
              /// Chat is a dedicated tab now - never rendered as a dashboard
              /// element. Filtered at read so legacy saved orders (the enum
              /// value stays persisted-data-safe) silently drop it.
              ..remove(DashboardElement.StreamChat);

        /// Only [DashboardStore.studioMode] is read here, so this Observer
        /// fires exclusively on studio-mode flips - not on the store's
        /// constant stream of stats/scene updates
        return Observer(
          builder: (context) => CustomSliverList(
            children: buildOrderedDashboardSlivers(
              order,
              settingsBox: settingsBox,
              studioModeActive: GetIt.instance<DashboardStore>().studioMode,
            ),
          ),
        );
      },
    );
  }
}
