import 'package:flutter/material.dart';

import '../../types/enums/hive_keys.dart';
import '../../types/enums/settings_keys.dart';
import '../../utils/styling_helper.dart';
import 'hive_builder.dart';

class ResponsiveWidgetWrapper extends StatelessWidget {
  final Widget mobileWidget;
  final Widget tabletWidget;

  const ResponsiveWidgetWrapper({
    super.key,
    required this.mobileWidget,
    required this.tabletWidget,
  });

  @override
  Widget build(BuildContext context) {
    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [SettingsKeys.EnforceTabletMode],
      builder: (context, settingsBox, child) =>
          MediaQuery.sizeOf(context).width > StylingHelper.max_width_mobile ||
                  settingsBox.get(SettingsKeys.EnforceTabletMode.name,
                      defaultValue: false)
              ? this.tabletWidget
              : this.mobileWidget,
    );
  }
}
